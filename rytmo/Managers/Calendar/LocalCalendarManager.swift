import Foundation
import SwiftData
import Combine
import SwiftUI
import EventKit

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
