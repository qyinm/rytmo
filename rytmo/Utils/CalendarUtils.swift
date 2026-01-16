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
    
    /// Arranges events into visual slots for a specific week (row)
    /// - Parameters:
    ///   - days: Array of 7 dates representing the week
    ///   - events: All events to consider
    /// - Returns: A dictionary mapping each Date to a list of events (with nil for empty slots)
    static func arrangeEventsInSlots(for days: [Date], events: [CalendarEventProtocol]) -> [Date: [CalendarEventProtocol?]] {
        guard !days.isEmpty else { return [:] }
        let weekStart = days[0]
        let weekEnd = days[lastIndex(of: days)] ?? days[6]
        let nextWeekStart = calendar.date(byAdding: .day, value: 1, to: weekEnd)!
        
        let weekEvents = events.filter { event in
            guard let start = event.eventStartDate, let end = event.eventEndDate else { return false }
            return start < nextWeekStart && end > weekStart
        }.sorted { e1, e2 in
            let s1 = e1.eventStartDate ?? Date.distantPast
            let s2 = e2.eventStartDate ?? Date.distantPast
            if s1 != s2 { return s1 < s2 }
            
            let d1 = (e1.eventEndDate ?? s1).timeIntervalSince(s1)
            let d2 = (e2.eventEndDate ?? s2).timeIntervalSince(s2)
            return d1 > d2
        }
        
        var slots: [Date: [CalendarEventProtocol?]] = [:]
        for day in days { slots[day] = [] }
        
        for event in weekEvents {
            let start = event.eventStartDate ?? weekStart
            let end = event.eventEndDate ?? weekEnd
            
            let overlappingDays = days.filter { day in
                let dayStart = calendar.startOfDay(for: day)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                return start < dayEnd && end > dayStart
            }
            
            guard !overlappingDays.isEmpty else { continue }
            
            var slotIndex = 0
            while true {
                var isAvailable = true
                for day in overlappingDays {
                    let daySlots = slots[day]!
                    if slotIndex < daySlots.count && daySlots[slotIndex] != nil {
                        isAvailable = false
                        break
                    }
                }
                
                if isAvailable {
                    break
                }
                slotIndex += 1
            }
            
            for day in overlappingDays {
                var daySlots = slots[day]!
                while daySlots.count <= slotIndex {
                    daySlots.append(nil)
                }
                daySlots[slotIndex] = event
                slots[day] = daySlots
            }
        }
        
        return slots
    }
    
    private static func lastIndex(of array: [Date]) -> Int {
        return array.count - 1
    }
}
