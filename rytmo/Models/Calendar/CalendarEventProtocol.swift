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
    var eventEndDate: Date? { event.endDate }
    var eventColor: Color {
        if let cgColor = event.calendar?.cgColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }
    var sourceName: String { "System" }
}
