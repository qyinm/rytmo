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
    
    /// Generate all dates to display for a given month (always 6 weeks / 42 days for fixed height)
    /// - Parameter date: Any date in the target month
    /// - Returns: Array of 42 dates to display in calendar grid
    static func generateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var dates: [Date] = []
        var current = monthFirstWeek.start
        
        // Always generate 42 days (6 weeks * 7 days) to maintain fixed height
        for _ in 0..<42 {
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
    
    /// Arranges events into visual slots for all weeks in a month (optimized version)
    /// - Parameters:
    ///   - allDays: All dates in the month grid
    ///   - events: All events to consider
    /// - Returns: A dictionary mapping each Date to a list of events (with nil for empty slots)
    static func arrangeEventsInSlotsForMonth(allDays: [Date], events: [CalendarEventProtocol]) -> [Date: [CalendarEventProtocol?]] {
        guard !allDays.isEmpty else { return [:] }
        
        let monthStart = allDays.first!
        let monthEnd = allDays.last!
        let nextDayAfterMonth = calendar.date(byAdding: .day, value: 1, to: monthEnd)!
        
        // Pre-compute day indices for O(1) lookup
        var dayToIndex: [Date: Int] = [:]
        for (index, day) in allDays.enumerated() {
            dayToIndex[calendar.startOfDay(for: day)] = index
        }
        
        let relevantEvents = events.filter { event in
            guard let start = event.eventStartDate, let end = event.eventEndDate else { return false }
            return start < nextDayAfterMonth && end > monthStart
        }.sorted { e1, e2 in
            let s1 = e1.eventStartDate ?? Date.distantPast
            let s2 = e2.eventStartDate ?? Date.distantPast
            if s1 != s2 { return s1 < s2 }
            let d1 = (e1.eventEndDate ?? s1).timeIntervalSince(s1)
            let d2 = (e2.eventEndDate ?? s2).timeIntervalSince(s2)
            return d1 > d2
        }
        
        // Use array-based slots for faster access
        var slotsArray: [[CalendarEventProtocol?]] = Array(repeating: [], count: allDays.count)
        
        for event in relevantEvents {
            let start = event.eventStartDate ?? monthStart
            var end = event.eventEndDate ?? monthEnd
            
            // Handle zero-duration events (e.g., all-day events with same start/end date)
            // These should display on at least the start day
            if start >= end, let adjustedEnd = calendar.date(byAdding: .day, value: 1, to: start) {
                end = adjustedEnd
            }
            
            // For all-day events, end date is inclusive (e.g., Jan 30 means "including Jan 30")
            // Convert to exclusive end for comparison by adding 1 day
            let effectiveEnd: Date
            if event.isAllDay, let nextDay = calendar.date(byAdding: .day, value: 1, to: end) {
                effectiveEnd = nextDay
            } else {
                effectiveEnd = end
            }
            
            // Find overlapping day indices using binary search approach
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: effectiveEnd)
            
            var startIdx = dayToIndex[startDay] ?? 0
            var endIdx = allDays.count - 1
            
            // Find actual range
            for i in 0..<allDays.count {
                let dayStart = calendar.startOfDay(for: allDays[i])
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                if start < dayEnd && effectiveEnd > dayStart {
                    startIdx = i
                    break
                }
            }
            for i in stride(from: allDays.count - 1, through: 0, by: -1) {
                let dayStart = calendar.startOfDay(for: allDays[i])
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                if start < dayEnd && effectiveEnd > dayStart {
                    endIdx = i
                    break
                }
            }
            
            guard startIdx <= endIdx else { continue }
            
            // Find available slot
            var slotIndex = 0
            outer: while true {
                for i in startIdx...endIdx {
                    if slotIndex < slotsArray[i].count && slotsArray[i][slotIndex] != nil {
                        slotIndex += 1
                        continue outer
                    }
                }
                break
            }
            
            // Assign event to slot
            for i in startIdx...endIdx {
                while slotsArray[i].count <= slotIndex {
                    slotsArray[i].append(nil)
                }
                slotsArray[i][slotIndex] = event
            }
        }
        
        // Convert to dictionary
        var result: [Date: [CalendarEventProtocol?]] = [:]
        for (index, day) in allDays.enumerated() {
            result[day] = slotsArray[index]
        }
        
        return result
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
