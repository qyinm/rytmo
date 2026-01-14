import Foundation
import SwiftData
import Combine
import SwiftUI
import EventKit

// Unified protocol for all calendar sources
protocol CalendarEventProtocol {
    var eventIdentifier: String { get }
    var eventTitle: String? { get }
    var eventStartDate: Date? { get }
    var eventEndDate: Date? { get }
    var eventColor: Color { get }
    var sourceName: String { get }
}

@MainActor
class LocalCalendarManager: ObservableObject {
    static let shared = LocalCalendarManager()
    
    private var modelContext: ModelContext?
    @Published var events: [LocalCalendarEvent] = []
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchEvents()
    }
    
    func fetchEvents() {
        guard let context = modelContext else { return }
        
        let start = Date()
        let end = Calendar.current.date(byAdding: .hour, value: 24, to: start) ?? start.addingTimeInterval(24 * 3600)
        
        let descriptor = FetchDescriptor<LocalCalendarEvent>(
            predicate: #Predicate { $0.startDate < end && $0.endDate > start },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            self.events = try context.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch local events: \(error)")
        }
    }
    
    func addEvent(title: String, startDate: Date, duration: TimeInterval, colorHex: String) {
        guard let context = modelContext else { return }
        
        let newEvent = LocalCalendarEvent(
            title: title,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(duration),
            colorHex: colorHex
        )
        
        context.insert(newEvent)
        fetchEvents()
    }
}

// Wrapper for EKEvent to ensure protocol conformance
struct SystemCalendarEvent: CalendarEventProtocol {
    private let event: EKEvent
    
    init(event: EKEvent) {
        self.event = event
    }
    
    var eventIdentifier: String { event.eventIdentifier }
    var eventTitle: String? { event.title }
    var eventStartDate: Date? { event.startDate }
    var eventEndDate: Date? { event.endDate }
    var eventColor: Color {
        if let cgColor = event.calendar?.cgColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }
    var sourceName: String { "System" }
}

extension LocalCalendarEvent: CalendarEventProtocol {
    var eventIdentifier: String { self.id.uuidString }
    var eventTitle: String? { self.title }
    var eventStartDate: Date? { self.startDate }
    var eventEndDate: Date? { self.endDate }
    var eventColor: Color { Color(hex: self.colorHex) }
    var sourceName: String { "Rytmo" }
}
