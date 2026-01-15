import Foundation
import SwiftData
import SwiftUI

@Model
final class LocalCalendarEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String
    var startDate: Date
    var endDate: Date
    var colorHex: String
    var isAllDay: Bool
    
    // Sync metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String, 
         note: String = "", 
         startDate: Date, 
         endDate: Date, 
         colorHex: String = "#007AFF", 
         isAllDay: Bool = false) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.startDate = startDate
        self.endDate = endDate
        self.colorHex = colorHex
        self.isAllDay = isAllDay
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
