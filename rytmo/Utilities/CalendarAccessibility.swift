//
//  CalendarAccessibility.swift
//  rytmo
//

import Foundation

enum CalendarAccessibility {
    static func eventLabel(for event: CalendarEventProtocol) -> String {
        let title = event.eventTitle ?? "Untitled event"
        if let startDate = event.eventStartDate {
            let time = startDate.formatted(date: .omitted, time: .shortened)
            return "\(title), \(time), \(event.sourceName)"
        }
        return "\(title), \(event.sourceName)"
    }

    static func dayLabel(for date: Date, eventCount: Int, todoCount: Int) -> String {
        let dateStr = date.formatted(.dateTime.month(.wide).day())
        var parts = [dateStr]
        if eventCount > 0 { parts.append("\(eventCount) events") }
        if todoCount > 0 { parts.append("\(todoCount) tasks") }
        if eventCount == 0 && todoCount == 0 { parts.append("no events or tasks") }
        return parts.joined(separator: ", ")
    }
}