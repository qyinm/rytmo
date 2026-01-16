//
//  CalendarUtils.swift
//  rytmo
//
//  Shared calendar utility functions
//

import Foundation
import SwiftUI

/// Shared calendar utilities to avoid code duplication
enum CalendarUtils {
    
    /// Shared Calendar instance
    static let calendar = Calendar.current
    
    /// Generate all dates to display for a given month (including padding days from adjacent months)
    /// - Parameter date: Any date in the target month
    /// - Returns: Array of dates to display in calendar grid
    static func generateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        var dates: [Date] = []
        var current = monthFirstWeek.start
        
        while current < monthLastWeek.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        return dates
    }
    
    static func events(for date: Date, from events: [CalendarEventProtocol]) -> [CalendarEventProtocol] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return events.filter { event in
            guard let startDate = event.eventStartDate,
                  let endDate = event.eventEndDate else { return false }
            
            return startDate < endOfDay && endDate > startOfDay
        }
    }
    
    /// Check if any events exist for a specific date
    /// - Parameters:
    ///   - date: Target date to check
    ///   - events: Array of calendar events to check
    /// - Returns: True if at least one event exists on the date
    static func hasEvents(for date: Date, in events: [CalendarEventProtocol]) -> Bool {
        events.contains { event in
            guard let eventDate = event.eventStartDate else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
    }
    
    /// Check if a date is in the same month as another date
    static func isDate(_ date: Date, inSameMonthAs otherDate: Date) -> Bool {
        calendar.isDate(date, equalTo: otherDate, toGranularity: .month)
    }
}
