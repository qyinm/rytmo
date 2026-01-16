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
    let localManager = LocalCalendarManager.shared
    let googleManager = GoogleCalendarManager.shared
    
    @Published var mergedEvents: [CalendarEventProtocol] = []
    @Published var systemEvents: [CalendarEventProtocol] = []
    @Published var isAuthorized: Bool = false
    
    @Published var currentReferenceDate: Date = Date()
    
    @Published var currentMonthDays: [Date] = []
    @Published var eventSlots: [Date: [CalendarEventProtocol?]] = [:]
    @Published var eventsByDate: [Date: [CalendarEventProtocol]] = [:]
    
    @AppStorage("calendar_show_system") var showSystem: Bool = true
    @AppStorage("calendar_show_rytmo") var showLocal: Bool = true
    @AppStorage("calendar_show_google") var showGoogle: Bool = true
    @AppStorage("calendar_event_range_hours") var eventRangeHours: Int = CalendarConfig.defaultEventRangeHours
    
    private var cancellables = Set<AnyCancellable>()
    private var systemFetchTask: Task<Void, Never>?
    private var aggregateDebounceTask: Task<Void, Never>?
    
    private init() {
        setupObservers()
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
        localManager.$events
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.aggregateEvents() }
            .store(in: &cancellables)
            
        googleManager.$events
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.aggregateEvents() }
            .store(in: &cancellables)
            
        $systemEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.aggregateEvents() }
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
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            if Task.isCancelled { return }
            
            var events: [CalendarEventProtocol] = []
            
            if self.showLocal {
                events.append(contentsOf: self.localManager.events.map { $0 as CalendarEventProtocol })
            }
            
            if self.showGoogle && self.googleManager.isAuthorized {
                events.append(contentsOf: self.googleManager.events.map { $0 as CalendarEventProtocol })
            }
            
            if self.showSystem && self.isAuthorized {
                events.append(contentsOf: self.systemEvents)
            }
            
            let sortedEvents = await Task.detached(priority: .userInitiated) {
                events.sorted {
                    ($0.eventStartDate ?? Date.distantPast) < ($1.eventStartDate ?? Date.distantPast)
                }
            }.value
            
            if Task.isCancelled { return }
            
            self.mergedEvents = sortedEvents
            self.computeOptimizedData()
        }
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
    
    func toggleSource(system: Bool? = nil, local: Bool? = nil, google: Bool? = nil) {
        if let system = system { self.showSystem = system }
        if let local = local { self.showLocal = local }
        if let google = google { self.showGoogle = google }
        loadEvents(for: currentReferenceDate)
    }
}
