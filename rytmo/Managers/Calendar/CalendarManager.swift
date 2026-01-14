import Foundation
import EventKit
import Combine
import SwiftUI

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    private let localManager = LocalCalendarManager.shared
    
    @Published var mergedEvents: [CalendarEventProtocol] = []
    @Published var isAuthorized: Bool = false
    
    @AppStorage("calendar_show_system") var showSystem: Bool = true
    @AppStorage("calendar_show_rytmo") var showLocal: Bool = true
    
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
    }
    
    func checkPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            self.isAuthorized = true
            refresh()
        default:
            self.isAuthorized = false
        }
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
            if granted {
                refresh()
            }
        } catch {
            print("❌ Calendar access request failed: \(error.localizedDescription)")
            self.isAuthorized = false
        }
    }
    
    func refresh() {
        var allEvents: [CalendarEventProtocol] = []
        
        if showLocal {
            allEvents.append(contentsOf: localManager.events.map { $0 as CalendarEventProtocol })
        }
        
        if showSystem && isAuthorized {
            let start = Date()
            let end = Calendar.current.date(byAdding: .hour, value: 24, to: start) ?? start.addingTimeInterval(24 * 3600)
            let calendars = eventStore.calendars(for: .event)
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
            let systemEvents = eventStore.events(matching: predicate).map { SystemCalendarEvent(event: $0) }
            allEvents.append(contentsOf: systemEvents.map { $0 as CalendarEventProtocol })
        }
        
        self.mergedEvents = allEvents.sorted { 
            ($0.eventStartDate ?? Date.distantPast) < ($1.eventStartDate ?? Date.distantPast)
        }
    }
    
    func toggleSource(system: Bool? = nil, local: Bool? = nil) {
        if let system = system { self.showSystem = system }
        if let local = local { self.showLocal = local }
        refresh()
    }
}
