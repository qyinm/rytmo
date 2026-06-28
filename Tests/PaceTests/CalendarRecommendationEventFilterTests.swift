import Foundation
import SwiftUI
import Testing
@testable import Pace

@Suite("Calendar recommendation event filter")
struct CalendarRecommendationEventFilterTests {
    @Test("Returns only upcoming timed events inside the requested window")
    func filtersRecommendationEvents() {
        let now = date(hour: 10)
        let inWindow = fakeEvent(start: now.addingTimeInterval(20 * 60))
        let events: [CalendarEventProtocol] = [
            fakeEvent(start: nil),
            fakeEvent(start: now.addingTimeInterval(-30 * 60), end: now.addingTimeInterval(-10 * 60)),
            fakeEvent(start: now.addingTimeInterval(5 * 60), isAllDay: true),
            inWindow,
            fakeEvent(start: now.addingTimeInterval(90 * 60))
        ]

        let result = CalendarRecommendationEventFilter.upcomingEvents(
            fromSorted: events,
            startDate: now,
            endDate: now.addingTimeInterval(60 * 60)
        )

        #expect(result == [
            NextSessionCalendarEvent(
                startDate: inWindow.eventStartDate!,
                endDate: inWindow.eventEndDate,
                isAllDay: false
            )
        ])
    }

    private func fakeEvent(
        start: Date?,
        end: Date? = nil,
        isAllDay: Bool = false
    ) -> FakeCalendarEvent {
        FakeCalendarEvent(
            eventStartDate: start,
            eventEndDate: end ?? start?.addingTimeInterval(30 * 60),
            isAllDay: isAllDay
        )
    }

    private func date(hour: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar.current
        components.year = 2026
        components.month = 6
        components.day = 28
        components.hour = hour

        return components.date!
    }
}

private struct FakeCalendarEvent: CalendarEventProtocol {
    let eventStartDate: Date?
    let eventEndDate: Date?
    let isAllDay: Bool

    var eventIdentifier: String { UUID().uuidString }
    var eventTitle: String? { "Event" }
    var eventColor: Color { .blue }
    var sourceName: String { "Test" }
    var eventLocation: String? { nil }
    var eventNotes: String? { nil }
    var calendarId: String? { nil }
}
