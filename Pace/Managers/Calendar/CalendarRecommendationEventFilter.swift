import Foundation

enum CalendarRecommendationEventFilter {
    static func upcomingEvents(
        fromSorted events: [CalendarEventProtocol],
        startDate: Date,
        endDate: Date
    ) -> [NextSessionCalendarEvent] {
        var recommendationEvents: [NextSessionCalendarEvent] = []

        for event in events {
            guard let eventStartDate = event.eventStartDate else {
                continue
            }

            if eventStartDate > endDate {
                break
            }

            guard event.isAllDay == false,
                  eventStartDate > startDate else {
                continue
            }

            if let eventEndDate = event.eventEndDate, eventEndDate <= startDate {
                continue
            }

            recommendationEvents.append(NextSessionCalendarEvent(
                startDate: eventStartDate,
                endDate: event.eventEndDate,
                isAllDay: event.isAllDay
            ))
        }

        return recommendationEvents
    }
}
