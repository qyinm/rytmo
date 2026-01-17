import SwiftUI

/// Represents a calendar (container of events)
struct CalendarInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let color: Color
    let sourceTitle: String // e.g., "Google (qusseun@gmail.com)", "iCloud"
    let type: CalendarType
    var isSelected: Bool = true
    
    enum CalendarType {
        case google
        case system
    }
}

struct CalendarGroup: Identifiable {
    let id: String
    let sourceTitle: String
    var calendars: [CalendarInfo]
}
