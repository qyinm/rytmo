//
//  CalendarEventProtocol.swift
//  rytmo
//
//  Unified protocol for all calendar sources
//

import Foundation
import SwiftUI
import EventKit

/// Unified protocol for all calendar sources (Local, System, Google)
protocol CalendarEventProtocol {
    var eventIdentifier: String { get }
    var eventTitle: String? { get }
    var eventStartDate: Date? { get }
    var eventEndDate: Date? { get }
    var eventColor: Color { get }
    var sourceName: String { get }
    
    // Additional properties for edit/delete
    var isAllDay: Bool { get }
    var eventLocation: String? { get }
    var eventNotes: String? { get }
    var calendarId: String? { get }
}

// MARK: - System Calendar Event Wrapper

/// Wrapper for EKEvent to ensure protocol conformance
struct SystemCalendarEvent: CalendarEventProtocol {
    private let event: EKEvent
    
    init(event: EKEvent) {
        self.event = event
    }
    
    var eventIdentifier: String { event.eventIdentifier }
    var eventTitle: String? { event.title }
    var eventStartDate: Date? { event.startDate }
    
    // For all-day events, EventKit stores exclusive end date (next day)
    // We convert it to inclusive end date (same day) for app display
    var eventEndDate: Date? {
        guard let date = event.endDate else { return nil }
        
        if event.isAllDay {
            return Calendar.current.date(byAdding: .day, value: -1, to: date)
        }
        
        return date
    }
    var eventColor: Color {
        if let cgColor = event.calendar?.cgColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }
    var sourceName: String { "System" }
    
    // Additional properties
    var isAllDay: Bool { event.isAllDay }
    var eventLocation: String? { event.location }
    var eventNotes: String? { event.notes }
    var calendarId: String? { event.calendar?.calendarIdentifier }
}
