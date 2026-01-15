//
//  CalendarUtilsTests.swift
//  rytmoTests
//
//  Unit tests for CalendarUtils
//

import XCTest
@testable import rytmo

final class CalendarUtilsTests: XCTestCase {
    
    // MARK: - generateDaysInMonth Tests
    
    func testGenerateDaysInMonth_ReturnsNonEmptyArray() {
        // Given
        let date = Date()
        
        // When
        let days = CalendarUtils.generateDaysInMonth(for: date)
        
        // Then
        XCTAssertFalse(days.isEmpty, "Should return at least some days")
    }
    
    func testGenerateDaysInMonth_ReturnsMultipleOf7() {
        // Given: A date in January 2026
        let components = DateComponents(year: 2026, month: 1, day: 15)
        let date = Calendar.current.date(from: components)!
        
        // When
        let days = CalendarUtils.generateDaysInMonth(for: date)
        
        // Then: Calendar grid should have complete weeks (multiple of 7)
        XCTAssertEqual(days.count % 7, 0, "Days count should be a multiple of 7 for complete weeks")
    }
    
    func testGenerateDaysInMonth_ContainsFirstDayOfMonth() {
        // Given: A date in January 2026
        let components = DateComponents(year: 2026, month: 1, day: 15)
        let date = Calendar.current.date(from: components)!
        
        // When
        let days = CalendarUtils.generateDaysInMonth(for: date)
        
        // Then: Should contain January 1, 2026
        let firstDayComponents = DateComponents(year: 2026, month: 1, day: 1)
        let firstDay = Calendar.current.date(from: firstDayComponents)!
        
        let containsFirstDay = days.contains { CalendarUtils.calendar.isDate($0, inSameDayAs: firstDay) }
        XCTAssertTrue(containsFirstDay, "Should contain the first day of the month")
    }
    
    func testGenerateDaysInMonth_ContainsLastDayOfMonth() {
        // Given: A date in January 2026
        let components = DateComponents(year: 2026, month: 1, day: 15)
        let date = Calendar.current.date(from: components)!
        
        // When
        let days = CalendarUtils.generateDaysInMonth(for: date)
        
        // Then: Should contain January 31, 2026
        let lastDayComponents = DateComponents(year: 2026, month: 1, day: 31)
        let lastDay = Calendar.current.date(from: lastDayComponents)!
        
        let containsLastDay = days.contains { CalendarUtils.calendar.isDate($0, inSameDayAs: lastDay) }
        XCTAssertTrue(containsLastDay, "Should contain the last day of the month")
    }
    
    // MARK: - events(for:from:) Tests
    
    func testEventsForDate_ReturnsMatchingEvents() {
        // Given
        let targetDate = Date()
        let mockEvents = [
            MockCalendarEvent(id: "1", startDate: targetDate),
            MockCalendarEvent(id: "2", startDate: targetDate.addingTimeInterval(3600)),
            MockCalendarEvent(id: "3", startDate: targetDate.addingTimeInterval(86400)) // Tomorrow
        ]
        
        // When
        let filteredEvents = CalendarUtils.events(for: targetDate, from: mockEvents)
        
        // Then
        XCTAssertEqual(filteredEvents.count, 2, "Should return 2 events for today")
    }
    
    func testEventsForDate_ReturnsEmptyForNoMatches() {
        // Given
        let targetDate = Date()
        let tomorrow = targetDate.addingTimeInterval(86400)
        let mockEvents = [
            MockCalendarEvent(id: "1", startDate: tomorrow)
        ]
        
        // When
        let filteredEvents = CalendarUtils.events(for: targetDate, from: mockEvents)
        
        // Then
        XCTAssertTrue(filteredEvents.isEmpty, "Should return empty array when no events match")
    }
    
    func testEventsForDate_HandlesNilStartDate() {
        // Given
        let targetDate = Date()
        let mockEvents = [
            MockCalendarEvent(id: "1", startDate: nil)
        ]
        
        // When
        let filteredEvents = CalendarUtils.events(for: targetDate, from: mockEvents)
        
        // Then
        XCTAssertTrue(filteredEvents.isEmpty, "Should exclude events with nil start date")
    }
    
    // MARK: - hasEvents(for:in:) Tests
    
    func testHasEvents_ReturnsTrueWhenEventsExist() {
        // Given
        let targetDate = Date()
        let mockEvents = [
            MockCalendarEvent(id: "1", startDate: targetDate)
        ]
        
        // When
        let hasEvents = CalendarUtils.hasEvents(for: targetDate, in: mockEvents)
        
        // Then
        XCTAssertTrue(hasEvents, "Should return true when events exist for the date")
    }
    
    func testHasEvents_ReturnsFalseWhenNoEvents() {
        // Given
        let targetDate = Date()
        let tomorrow = targetDate.addingTimeInterval(86400)
        let mockEvents = [
            MockCalendarEvent(id: "1", startDate: tomorrow)
        ]
        
        // When
        let hasEvents = CalendarUtils.hasEvents(for: targetDate, in: mockEvents)
        
        // Then
        XCTAssertFalse(hasEvents, "Should return false when no events exist for the date")
    }
    
    func testHasEvents_ReturnsFalseForEmptyArray() {
        // Given
        let targetDate = Date()
        let mockEvents: [MockCalendarEvent] = []
        
        // When
        let hasEvents = CalendarUtils.hasEvents(for: targetDate, in: mockEvents)
        
        // Then
        XCTAssertFalse(hasEvents, "Should return false for empty events array")
    }
    
    // MARK: - isDate(_:inSameMonthAs:) Tests
    
    func testIsDateInSameMonth_ReturnsTrueForSameMonth() {
        // Given
        let date1Components = DateComponents(year: 2026, month: 1, day: 1)
        let date2Components = DateComponents(year: 2026, month: 1, day: 31)
        let date1 = Calendar.current.date(from: date1Components)!
        let date2 = Calendar.current.date(from: date2Components)!
        
        // When
        let result = CalendarUtils.isDate(date1, inSameMonthAs: date2)
        
        // Then
        XCTAssertTrue(result, "Dates in the same month should return true")
    }
    
    func testIsDateInSameMonth_ReturnsFalseForDifferentMonths() {
        // Given
        let date1Components = DateComponents(year: 2026, month: 1, day: 15)
        let date2Components = DateComponents(year: 2026, month: 2, day: 15)
        let date1 = Calendar.current.date(from: date1Components)!
        let date2 = Calendar.current.date(from: date2Components)!
        
        // When
        let result = CalendarUtils.isDate(date1, inSameMonthAs: date2)
        
        // Then
        XCTAssertFalse(result, "Dates in different months should return false")
    }
    
    func testIsDateInSameMonth_ReturnsFalseForDifferentYears() {
        // Given
        let date1Components = DateComponents(year: 2025, month: 1, day: 15)
        let date2Components = DateComponents(year: 2026, month: 1, day: 15)
        let date1 = Calendar.current.date(from: date1Components)!
        let date2 = Calendar.current.date(from: date2Components)!
        
        // When
        let result = CalendarUtils.isDate(date1, inSameMonthAs: date2)
        
        // Then
        XCTAssertFalse(result, "Same month in different years should return false")
    }
}

// MARK: - Mock Objects

import SwiftUI

struct MockCalendarEvent: CalendarEventProtocol {
    let eventIdentifier: String
    let eventTitle: String?
    let eventStartDate: Date?
    let eventEndDate: Date?
    let eventColor: Color
    let sourceName: String
    
    init(
        id: String,
        title: String? = "Test Event",
        startDate: Date?,
        endDate: Date? = nil,
        color: Color = .blue,
        source: String = "Test"
    ) {
        self.eventIdentifier = id
        self.eventTitle = title
        self.eventStartDate = startDate
        self.eventEndDate = endDate ?? startDate?.addingTimeInterval(3600)
        self.eventColor = color
        self.sourceName = source
    }
}
