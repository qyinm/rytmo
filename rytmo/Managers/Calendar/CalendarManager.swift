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
    @Published var isAuthorized: Bool = false
    
    @AppStorage("calendar_show_system") var showSystem: Bool = true
    @AppStorage("calendar_show_rytmo") var showLocal: Bool = true
    @AppStorage("calendar_show_google") var showGoogle: Bool = true
    @AppStorage("calendar_event_range_hours") var eventRangeHours: Int = CalendarConfig.defaultEventRangeHours
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .EKEventStoreChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
            .store(in: &cancellables)
            
        localManager.$events
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
            
        googleManager.$events
            .sink { [weak self] _ in
                self?.refresh()
            }
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
        refresh()
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
            refresh()
        } catch {
            print("❌ System Calendar access failed: \(error.localizedDescription)")
        }
    }
    
    func refresh() {
        var allEvents: [CalendarEventProtocol] = []
        
        if showLocal {
            allEvents.append(contentsOf: localManager.events.map { $0 as CalendarEventProtocol })
        }
        
        if showGoogle && googleManager.isAuthorized {
            allEvents.append(contentsOf: googleManager.events.map { $0 as CalendarEventProtocol })
        }
        
        if showSystem && isAuthorized {
            let start = Date()
            let end = Calendar.current.date(byAdding: .hour, value: eventRangeHours, to: start) ?? start.addingTimeInterval(Double(eventRangeHours) * 3600)
            let calendars = eventStore.calendars(for: .event)
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
            let systemEvents = eventStore.events(matching: predicate).map { SystemCalendarEvent(event: $0) }
            allEvents.append(contentsOf: systemEvents.map { $0 as CalendarEventProtocol })
        }
        
        // Final sort and deduplication by title/start
        self.mergedEvents = allEvents.sorted { 
            ($0.eventStartDate ?? Date.distantPast) < ($1.eventStartDate ?? Date.distantPast)
        }
    }
    
    func toggleSource(system: Bool? = nil, local: Bool? = nil, google: Bool? = nil) {
        if let system = system { self.showSystem = system }
        if let local = local { self.showLocal = local }
        if let google = google { self.showGoogle = google }
        refresh()
    }
}
