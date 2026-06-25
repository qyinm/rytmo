import Foundation
import EventKit
import Combine
import SwiftUI

// MARK: - Calendar Configuration

struct CalendarOptimizedData {
    let days: [Date]
    let eventSlots: [Date: [CalendarEventProtocol?]]
    let eventsByDate: [Date: [CalendarEventProtocol]]
    
    static let empty = CalendarOptimizedData(
        days: [],
        eventSlots: [:],
        eventsByDate: [:]
    )
}

private enum CalendarConfig {
    /// Default event fetch range in hours
    static let defaultEventRangeHours = 24
}

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    let eventStore = EKEventStore()
    let googleManager = GoogleCalendarManager.shared
    
    private var mergedEvents: [CalendarEventProtocol] = []
    private var systemEvents: [CalendarEventProtocol] = []
    @Published var isAuthorized: Bool = false
    
    @Published var currentReferenceDate: Date = Date()
    
    @Published var optimizedData: CalendarOptimizedData = .empty
    
    var currentMonthDays: [Date] { optimizedData.days }
    var eventSlots: [Date: [CalendarEventProtocol?]] { optimizedData.eventSlots }
    var eventsByDate: [Date: [CalendarEventProtocol]] { optimizedData.eventsByDate }
    
    @Published var calendarGroups: [CalendarGroup] = []
    
    @AppStorage("calendar_show_system") var showSystem: Bool = true
    @AppStorage("calendar_show_google") var showGoogle: Bool = true
    @AppStorage("calendar_event_range_hours") var eventRangeHours: Int = CalendarConfig.defaultEventRangeHours
    @AppStorage("calendar_hidden_ids") private var hiddenCalendarIdsData: Data = Data()
    
    private var cancellables = Set<AnyCancellable>()
    private var systemFetchTask: Task<Void, Never>?
    private var aggregateDebounceTask: Task<Void, Never>?
    private var suppressSystemStoreRefreshUntil: Date?
    
    private init() {
        setupObservers()
        // Immediately show cached data on startup (like Notion Calendar)
        aggregateEventsImmediate()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .EKEventStoreChanged)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    if self.shouldSuppressSystemStoreRefresh() {
                        return
                    }
                    self.fetchSystemEvents(date: self.currentReferenceDate)
                }
            }
            .store(in: &cancellables)
            
        // Trigger aggregation when any source changes
        googleManager.$events
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.aggregateEvents() }
            .store(in: &cancellables)
            
        googleManager.$availableCalendars
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateCalendarGroups() }
            .store(in: &cancellables)
    }
    
    func checkPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            self.isAuthorized = true
        default:
            self.isAuthorized = false
        }
        
        googleManager.checkPermission()
        googleManager.fetchCalendarList()
        updateCalendarGroups()
        loadEvents(for: Date())
    }
    
    func requestAccess() async {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            
            self.isAuthorized = granted
            loadEvents(for: currentReferenceDate)
        } catch {
            print("❌ System Calendar access failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Loading & Aggregation
    
    func refresh(date: Date) {
        loadEvents(for: date)
    }
    
    func loadEvents(for date: Date) {
        self.currentReferenceDate = date
        
        if showGoogle && googleManager.isAuthorized {
            googleManager.fetchEvents(date: date)
        }
        
        if showSystem && isAuthorized {
            fetchSystemEvents(date: date)
        }
        
        aggregateEvents()
    }
    
    private func fetchSystemEvents(date: Date) {
        systemFetchTask?.cancel()
        
        systemFetchTask = Task {
            let calendar = Calendar.current
            guard let monthRange = calendar.dateInterval(of: .month, for: date) else { return }
            
            let monthDays = CalendarUtils.generateDaysInMonth(for: date)
            let start = monthDays.first ?? monthRange.start
            let end = calendar.date(byAdding: .day, value: 1, to: monthDays.last ?? monthRange.end) ?? monthRange.end
            
            let calendars = self.eventStore.calendars(for: .event)
            let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
            let events = self.eventStore.events(matching: predicate).map { SystemCalendarEvent(event: $0) }
            
            if !Task.isCancelled {
                guard !self.matchesCurrentSystemEvents(events) else { return }
                self.systemEvents = events
                self.aggregateEvents()
            }
        }
    }

    private func shouldSuppressSystemStoreRefresh(now: Date = Date()) -> Bool {
        guard let suppressedUntil = suppressSystemStoreRefreshUntil else {
            return false
        }

        if suppressedUntil > now {
            return true
        }

        suppressSystemStoreRefreshUntil = nil
        return false
    }

    private func suppressUpcomingSystemStoreRefresh(for interval: TimeInterval = 1.0) {
        suppressSystemStoreRefreshUntil = Date().addingTimeInterval(interval)
    }
    
    private func aggregateEvents() {
        aggregateDebounceTask?.cancel()
        
        aggregateDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000) // 30ms debounce
            if Task.isCancelled { return }
            aggregateEventsImmediate()
        }
    }
    
    /// Immediately aggregate events without debounce - used for initial load
    private func aggregateEventsImmediate() {
        var events: [CalendarEventProtocol] = []
        let hidden = self.hiddenCalendarIds
        
        // Use cached Google events even if not yet "authorized" (cache loaded in init)
        if self.showGoogle && !googleManager.events.isEmpty {
            let googleEvents = googleManager.events
                .filter { hidden.isEmpty || !hidden.contains($0.calendarId ?? "") }
                .map { $0 as CalendarEventProtocol }
            events.append(contentsOf: googleEvents)
        }
        
        if self.showSystem && !systemEvents.isEmpty {
            let systemEventsFiltered = systemEvents
                .filter { hidden.isEmpty || !hidden.contains($0.calendarId ?? "") }
            events.append(contentsOf: systemEventsFiltered)
        }
        
        // Sort synchronously for immediate display
        self.mergedEvents = events.sorted {
            ($0.eventStartDate ?? Date.distantPast) < ($1.eventStartDate ?? Date.distantPast)
        }
        
        // Compute optimized data on main actor
        computeOptimizedData()
    }
    
    private func computeOptimizedData() {
        let days = CalendarUtils.generateDaysInMonth(for: currentReferenceDate)
        let slots = CalendarUtils.arrangeEventsInSlotsForMonth(allDays: days, events: mergedEvents)
        
        var byDate: [Date: [CalendarEventProtocol]] = [:]
        
        // Initialize buckets for the days in the current view
        for day in days {
            byDate[day] = []
        }
        
        let calendar = Calendar.current
        
        // O(N) Algorithm: Iterate through events once and assign to day buckets
        if let firstDay = days.first, let lastDay = days.last {
            for event in mergedEvents {
                guard let start = event.eventStartDate, var end = event.eventEndDate else { continue }
                
                // Handle zero-duration events (all-day events with same start/end)
                // This already converts to exclusive end date, so skip all-day fix below
                var wasZeroDuration = false
                if start >= end, let adjusted = calendar.date(byAdding: .day, value: 1, to: start) {
                    end = adjusted
                    wasZeroDuration = true
                }
                
                // For multi-day all-day events, end date is inclusive (e.g., Jan 30 means "including Jan 30")
                // Convert to exclusive end for comparison by adding 1 day
                // Skip if zero-duration fix was already applied (single-day all-day events)
                let effectiveEnd: Date
                if event.isAllDay && !wasZeroDuration, let nextDay = calendar.date(byAdding: .day, value: 1, to: end) {
                    effectiveEnd = nextDay
                } else {
                    effectiveEnd = end
                }
                
                let startBucket = calendar.startOfDay(for: start)
                var current = startBucket
                
                // Add event to all days it covers
                while current < effectiveEnd {
                    // Optimization: stop if we passed the end of the month view
                    if current > lastDay { break }
                    
                    // Only add if this day is within our month view (key exists)
                    if current >= firstDay {
                        if byDate[current] != nil {
                            byDate[current]?.append(event)
                        }
                    }
                    
                    guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                    current = next
                }
            }
        }
        
        self.optimizedData = CalendarOptimizedData(
            days: days,
            eventSlots: slots,
            eventsByDate: byDate
        )
    }
    
    func toggleSource(system: Bool? = nil, google: Bool? = nil) {
        if let system = system { self.showSystem = system }
        if let google = google { self.showGoogle = google }
        loadEvents(for: currentReferenceDate)
    }
    
    // MARK: - Calendar Visibility
    
    private var hiddenCalendarIds: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: hiddenCalendarIdsData)) ?? []
        }
        set {
            hiddenCalendarIdsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    func isCalendarVisible(_ calendarId: String) -> Bool {
        !hiddenCalendarIds.contains(calendarId)
    }
    
    func toggleCalendarVisibility(_ calendarId: String) {
        var hidden = hiddenCalendarIds
        if hidden.contains(calendarId) {
            hidden.remove(calendarId)
        } else {
            hidden.insert(calendarId)
        }
        hiddenCalendarIds = hidden
        
        // Refresh to apply visibility changes
        aggregateEvents()
    }
    
    private func updateCalendarGroups() {
        var groups: [CalendarGroup] = []
        
        // 1. Google Calendars (via API)
        if !googleManager.availableCalendars.isEmpty {
            // Group by account if possible, but for now just one group for Google API
            // Actually Google API usually returns the account email in summary of primary calendar, 
            // but let's assume one logged in user for now.
            // Or better, use the sourceTitle we set in GoogleCalendarManager
            
            let googleCals = googleManager.availableCalendars
            // Group by sourceTitle (which contains email)
            let groupedGoogle = Dictionary(grouping: googleCals) { $0.sourceTitle }
            
            for (source, cals) in groupedGoogle {
                groups.append(CalendarGroup(
                    id: "google_\(source)",
                    sourceTitle: source,
                    calendars: cals
                ))
            }
        }
        
        // 2. System Calendars
        if isAuthorized {
            let ekCalendars = eventStore.calendars(for: .event)
            let groupedSystem = Dictionary(grouping: ekCalendars) { $0.source.title }
            
            for (sourceTitle, calendars) in groupedSystem {
                let infos = calendars.map { cal in
                    CalendarInfo(
                        id: cal.calendarIdentifier,
                        title: cal.title,
                        color: Color(nsColor: cal.color),
                        sourceTitle: sourceTitle,
                        type: .system
                    )
                }
                groups.append(CalendarGroup(
                    id: "system_\(sourceTitle)",
                    sourceTitle: sourceTitle,
                    calendars: infos.sorted { $0.title < $1.title }
                ))
            }
        }
        
        self.calendarGroups = groups
    }

    private func matchesCurrentSystemEvents(_ events: [CalendarEventProtocol]) -> Bool {
        guard systemEvents.count == events.count else { return false }
        return zip(systemEvents, events).allSatisfy { lhs, rhs in
            lhs.eventIdentifier == rhs.eventIdentifier &&
            lhs.eventTitle == rhs.eventTitle &&
            lhs.eventStartDate == rhs.eventStartDate &&
            lhs.eventEndDate == rhs.eventEndDate &&
            lhs.isAllDay == rhs.isAllDay &&
            lhs.eventLocation == rhs.eventLocation &&
            lhs.eventNotes == rhs.eventNotes &&
            lhs.calendarId == rhs.calendarId
        }
    }

    private func removeSystemEventFromCache(eventId: String) {
        let filteredEvents = systemEvents.filter { $0.eventIdentifier != eventId }
        guard filteredEvents.count != systemEvents.count else { return }
        systemEvents = filteredEvents
        aggregateEventsImmediate()
    }

    private func upsertSystemEventInCache(
        _ event: CalendarEventProtocol,
        replacing originalEventId: String? = nil
    ) {
        let idsToReplace = Set([originalEventId, event.eventIdentifier].compactMap { $0 })
        systemEvents.removeAll { idsToReplace.contains($0.eventIdentifier) }
        systemEvents.append(event)
        systemEvents.sort {
            let lhsStart = $0.eventStartDate ?? .distantPast
            let rhsStart = $1.eventStartDate ?? .distantPast
            if lhsStart != rhsStart {
                return lhsStart < rhsStart
            }
            return $0.eventIdentifier < $1.eventIdentifier
        }
        aggregateEventsImmediate()
    }
    
    // MARK: - Write Permission

    /// Whether events can be created or edited for the given calendar source.
    func canWriteEvents(for calendarInfo: CalendarInfo) -> Bool {
        switch calendarInfo.type {
        case .system:
            return isAuthorized
        case .google:
            return googleManager.canWriteEvents
        }
    }

    /// Whether any connected calendar source allows event editing.
    var canWriteAnyCalendar: Bool {
        let hasWritableSystem = showSystem && isAuthorized
        let hasWritableGoogle = showGoogle && googleManager.canWriteEvents
        return hasWritableSystem || hasWritableGoogle
    }

    /// Whether Google Calendar is connected in read-only mode and needs a scope upgrade to edit.
    var googleNeedsScopeUpgrade: Bool {
        showGoogle && googleManager.needsScopeUpgrade
    }

    // MARK: - Create Event

    /// Creates a new event in the specified calendar (System or Google)
    /// - Parameters:
    ///   - title: Event title
    ///   - startDate: Start date/time
    ///   - endDate: End date/time
    ///   - isAllDay: Whether this is an all-day event
    ///   - calendarInfo: The target calendar information
    ///   - location: Optional location string
    ///   - notes: Optional description/notes
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendarInfo: CalendarInfo,
        location: String?,
        notes: String?
    ) async throws {
        guard canWriteEvents(for: calendarInfo) else {
            throw CalendarCreationError.notAuthorized
        }

        switch calendarInfo.type {
        case .system:
            suppressUpcomingSystemStoreRefresh()
            let createdEvent = try await createSystemEvent(
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                calendarId: calendarInfo.id,
                location: location,
                notes: notes
            )
            upsertSystemEventInCache(createdEvent)
        case .google:
            try await googleManager.createEvent(
                calendarId: calendarInfo.id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                location: location,
                notes: notes
            )
        }
    }
    
    /// Creates an event in the System (Apple) Calendar using EventKit
    private func createSystemEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendarId: String,
        location: String?,
        notes: String?
    ) async throws -> SystemCalendarEvent {
        guard isAuthorized else {
            throw CalendarCreationError.notAuthorized
        }
        
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarCreationError.calendarNotFound
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.calendar = calendar
        
        if let location = location, !location.isEmpty {
            event.location = location
        }
        
        if let notes = notes, !notes.isEmpty {
            event.notes = notes
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ System Calendar event created successfully: \(title)")
            return SystemCalendarEvent(event: event)
        } catch {
            print("❌ Failed to create System Calendar event: \(error.localizedDescription)")
            throw CalendarCreationError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Update Event
    
    /// Updates an existing event
    func updateEvent(
        event: CalendarEventProtocol,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendarInfo: CalendarInfo,
        location: String?,
        notes: String?
    ) async throws {
        guard canWriteEvents(for: calendarInfo) else {
            throw CalendarCreationError.notAuthorized
        }

        switch event.sourceName {
        case "System":
            suppressUpcomingSystemStoreRefresh()
            let updatedEvent = try await updateSystemEvent(
                eventId: event.eventIdentifier,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                calendarId: calendarInfo.id,
                location: location,
                notes: notes
            )
            upsertSystemEventInCache(updatedEvent, replacing: event.eventIdentifier)
        case "Google":
            let targetCalendarId = calendarInfo.id
            let sourceCalendarId = event.calendarId ?? targetCalendarId
            
            try await googleManager.updateEvent(
                eventId: event.eventIdentifier,
                calendarId: sourceCalendarId,
                targetCalendarId: targetCalendarId,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                location: location,
                notes: notes
            )
        default:
            throw CalendarCreationError.saveFailed("Unknown event source")
        }
    }
    
    private func updateSystemEvent(
        eventId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendarId: String,
        location: String?,
        notes: String?
    ) async throws -> SystemCalendarEvent {
        guard isAuthorized else {
            throw CalendarCreationError.notAuthorized
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarCreationError.saveFailed("Event not found")
        }
        
        // Update calendar if changed
        if let newCalendar = eventStore.calendar(withIdentifier: calendarId) {
            event.calendar = newCalendar
        }
        
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.location = location
        event.notes = notes
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ System Calendar event updated: \(title)")
            return SystemCalendarEvent(event: event)
        } catch {
            throw CalendarCreationError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Event
    
    /// Deletes an event
    func deleteEvent(event: CalendarEventProtocol) async throws {
        if event.sourceName == "Google" {
            guard googleManager.canWriteEvents else {
                throw CalendarCreationError.notAuthorized
            }
        } else if event.sourceName == "System" {
            guard isAuthorized else {
                throw CalendarCreationError.notAuthorized
            }
        }

        switch event.sourceName {
        case "System":
            suppressUpcomingSystemStoreRefresh()
            try await deleteSystemEvent(eventId: event.eventIdentifier)
            removeSystemEventFromCache(eventId: event.eventIdentifier)
        case "Google":
            guard let calendarId = event.calendarId else {
                throw CalendarCreationError.calendarNotFound
            }
            try await googleManager.deleteEvent(
                eventId: event.eventIdentifier,
                calendarId: calendarId
            )
        default:
            throw CalendarCreationError.saveFailed("Unknown event source")
        }
    }
    
    private func deleteSystemEvent(eventId: String) async throws {
        guard isAuthorized else {
            throw CalendarCreationError.notAuthorized
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarCreationError.saveFailed("Event not found")
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            print("✅ System Calendar event deleted")
        } catch {
            throw CalendarCreationError.saveFailed(error.localizedDescription)
        }
    }
}

// MARK: - Calendar Creation Errors

enum CalendarCreationError: LocalizedError {
    case notAuthorized
    case calendarNotFound
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar write access is not granted. Connect a calendar or upgrade permissions in Settings."
        case .calendarNotFound:
            return "Selected calendar not found."
        case .saveFailed(let message):
            return "Failed to save event: \(message)"
        }
    }
}
