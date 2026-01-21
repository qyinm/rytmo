import Foundation
import EventKit
import Combine
import SwiftUI

// MARK: - Calendar Configuration

private enum CalendarConfig {
    /// Default event fetch range in hours
    static let defaultEventRangeHours = 24
}

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    let eventStore = EKEventStore()
    let googleManager = GoogleCalendarManager.shared
    
    @Published var mergedEvents: [CalendarEventProtocol] = []
    @Published var systemEvents: [CalendarEventProtocol] = []
    @Published var isAuthorized: Bool = false
    
    @Published var currentReferenceDate: Date = Date()
    
    @Published var currentMonthDays: [Date] = []
    @Published var eventSlots: [Date: [CalendarEventProtocol?]] = [:]
    @Published var eventsByDate: [Date: [CalendarEventProtocol]] = [:]
    
    @Published var calendarGroups: [CalendarGroup] = []
    
    @AppStorage("calendar_show_system") var showSystem: Bool = true
    @AppStorage("calendar_show_google") var showGoogle: Bool = true
    @AppStorage("calendar_event_range_hours") var eventRangeHours: Int = CalendarConfig.defaultEventRangeHours
    @AppStorage("calendar_hidden_ids") private var hiddenCalendarIdsData: Data = Data()
    
    private var cancellables = Set<AnyCancellable>()
    private var systemFetchTask: Task<Void, Never>?
    private var aggregateDebounceTask: Task<Void, Never>?
    
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
                    self.fetchSystemEvents(date: self.currentReferenceDate)
                }
            }
            .store(in: &cancellables)
            
        // Trigger aggregation when any source changes
        googleManager.$events
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.aggregateEvents() }
            .store(in: &cancellables)
            
        $systemEvents
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
        computeOptimizedData()
    }
    
    private func fetchSystemEvents(date: Date) {
        systemFetchTask?.cancel()
        
        systemFetchTask = Task {
            let calendar = Calendar.current
            guard let monthRange = calendar.dateInterval(of: .month, for: date) else { return }
            
            let monthDays = CalendarUtils.generateDaysInMonth(for: date)
            let start = monthDays.first ?? monthRange.start
            let end = calendar.date(byAdding: .day, value: 1, to: monthDays.last ?? monthRange.end) ?? monthRange.end
            
            let events = await Task.detached(priority: .userInitiated) { [weak self] () -> [CalendarEventProtocol] in
                guard let self = self else { return [] }
                let calendars = self.eventStore.calendars(for: .event)
                let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
                return self.eventStore.events(matching: predicate).map { SystemCalendarEvent(event: $0) }
            }.value
            
            if !Task.isCancelled {
                self.systemEvents = events
            }
        }
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
        for day in days {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: day)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            byDate[startOfDay] = mergedEvents.filter { event in
                guard let start = event.eventStartDate, let end = event.eventEndDate else { return false }
                return start < endOfDay && end > startOfDay
            }
        }
        
        self.currentMonthDays = days
        self.eventSlots = slots
        self.eventsByDate = byDate
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
        switch calendarInfo.type {
        case .system:
            try await createSystemEvent(
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                calendarId: calendarInfo.id,
                location: location,
                notes: notes
            )
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
        
        // Refresh events after creation
        refresh(date: startDate)
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
    ) async throws {
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
        switch event.sourceName {
        case "System":
            try await updateSystemEvent(
                eventId: event.eventIdentifier,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                calendarId: calendarInfo.id,
                location: location,
                notes: notes
            )
        case "Google":
            // For Google, if calendar changed we need to move the event
            let targetCalendarId = calendarInfo.id
            let sourceCalendarId = event.calendarId ?? targetCalendarId
            
            try await googleManager.updateEvent(
                eventId: event.eventIdentifier,
                calendarId: sourceCalendarId,
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
        
        refresh(date: startDate)
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
    ) async throws {
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
        } catch {
            throw CalendarCreationError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Event
    
    /// Deletes an event
    func deleteEvent(event: CalendarEventProtocol) async throws {
        switch event.sourceName {
        case "System":
            try await deleteSystemEvent(eventId: event.eventIdentifier)
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
        
        refresh(date: currentReferenceDate)
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
            return "Calendar access not authorized. Please grant permission in System Settings."
        case .calendarNotFound:
            return "Selected calendar not found."
        case .saveFailed(let message):
            return "Failed to save event: \(message)"
        }
    }
}
