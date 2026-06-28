import Foundation
import Testing
@testable import Pace

@Suite("Next session recommendation engine")
struct NextSessionRecommendationEngineTests {
    private let engine = NextSessionRecommendationEngine()
    private let focusDuration: TimeInterval = 25 * 60

    @Test("Defaults to focus without claiming calendar clarity")
    func defaultsToFocusWhenIdleWithoutSignals() {
        let recommendation = engine.recommend(from: input(at: date(hour: 10)))

        #expect(recommendation?.sessionType == .focus)
        #expect(recommendation?.reason == .idleReady)
        #expect(recommendation?.reasonText.contains("calendar") == false)
    }

    @Test("Recommends short reset when a full focus block is poorly timed")
    func recommendsShortResetForUpcomingEventInsideFocusWindow() {
        let now = date(hour: 10)
        let event = event(start: now.addingTimeInterval(20 * 60))

        let recommendation = engine.recommend(from: input(at: now, events: [event]))

        #expect(recommendation?.sessionType == .shortReset)
        #expect(recommendation?.reason == .upcomingEventSoon(minutesUntilEvent: 20))
    }

    @Test("Recommends focus when there is enough time before the next event")
    func recommendsFocusWhenCalendarWindowIsLongEnough() {
        let now = date(hour: 10)
        let event = event(start: now.addingTimeInterval(45 * 60))

        let recommendation = engine.recommend(from: input(at: now, events: [event]))

        #expect(recommendation?.sessionType == .focus)
        #expect(recommendation?.reason == .enoughTimeBeforeEvent(minutesUntilEvent: 45))
    }

    @Test("Recommends wrap-up near a calendar event late in the day")
    func recommendsWrapUpForImmediateEventLateInDay() {
        let now = date(hour: 17, minute: 10)
        let event = event(start: now.addingTimeInterval(10 * 60))

        let recommendation = engine.recommend(from: input(at: now, events: [event]))

        #expect(recommendation?.sessionType == .wrapUp)
        #expect(recommendation?.reason == .upcomingEventAtEndOfDay(minutesUntilEvent: 10))
    }

    @Test("Infers broken rhythm from recent short focus sessions")
    func recommendsShortResetForRecentShortFocusAttempts() {
        let now = date(hour: 13)
        let sessions = [
            focusSession(start: now.addingTimeInterval(-90 * 60), duration: 4 * 60),
            focusSession(start: now.addingTimeInterval(-30 * 60), duration: 6 * 60)
        ]

        let recommendation = engine.recommend(from: input(at: now, sessions: sessions))

        #expect(recommendation?.sessionType == .shortReset)
        #expect(recommendation?.reason == .recentShortSessions)
    }

    @Test("Does not infer broken rhythm from one short or old session")
    func ignoresInsufficientBrokenRhythmSignals() {
        let now = date(hour: 13)
        let sessions = [
            focusSession(start: now.addingTimeInterval(-90 * 60), duration: 4 * 60),
            focusSession(start: now.addingTimeInterval(-5 * 60 * 60), duration: 4 * 60)
        ]

        let recommendation = engine.recommend(from: input(at: now, sessions: sessions))

        #expect(recommendation?.sessionType == .focus)
        #expect(recommendation?.reason == .idleReady)
    }

    @Test("Ignores unusable calendar snapshots defensively")
    func ignoresAllDayEndedAndPastEvents() {
        let now = date(hour: 10)
        let events = [
            event(start: now.addingTimeInterval(5 * 60), isAllDay: true),
            event(start: now.addingTimeInterval(-30 * 60), end: now.addingTimeInterval(-10 * 60)),
            event(start: now),
            event(start: now.addingTimeInterval(45 * 60))
        ]

        let recommendation = engine.recommend(from: input(at: now, events: events))

        #expect(recommendation?.sessionType == .focus)
        #expect(recommendation?.reason == .enoughTimeBeforeEvent(minutesUntilEvent: 45))
    }

    @Test("Recommends wrap-up after local wrap-up hour")
    func recommendsWrapUpAfterFivePM() {
        let recommendation = engine.recommend(from: input(at: date(hour: 18)))

        #expect(recommendation?.sessionType == .wrapUp)
        #expect(recommendation?.reason == .endOfDay)
    }

    @Test("Does not recommend while the timer is active")
    func returnsNilWhenTimerIsActive() {
        let recommendation = engine.recommend(
            from: input(at: date(hour: 10), allowsRecommendation: false)
        )

        #expect(recommendation == nil)
    }

    @Test("Due todos can strengthen the default focus reason")
    func recommendsFocusForDueTodos() {
        let now = date(hour: 10)
        let todos = [
            NextSessionTodoSnapshot(dueDate: now.addingTimeInterval(2 * 60 * 60)),
            NextSessionTodoSnapshot(dueDate: nil)
        ]

        let recommendation = engine.recommend(from: input(at: now, todos: todos))

        #expect(recommendation?.sessionType == .focus)
        #expect(recommendation?.reason == .dueTodos(count: 1))
    }

    private func input(
        at now: Date,
        allowsRecommendation: Bool = true,
        events: [NextSessionCalendarEvent] = [],
        sessions: [NextSessionFocusSessionSnapshot] = [],
        todos: [NextSessionTodoSnapshot] = []
    ) -> NextSessionRecommendationInput {
        NextSessionRecommendationInput(
            now: now,
            allowsRecommendation: allowsRecommendation,
            focusDuration: focusDuration,
            upcomingEvents: events,
            recentSessions: sessions,
            activeTodos: todos
        )
    }

    private func event(start: Date, end: Date? = nil, isAllDay: Bool = false) -> NextSessionCalendarEvent {
        NextSessionCalendarEvent(
            startDate: start,
            endDate: end ?? start.addingTimeInterval(30 * 60),
            isAllDay: isAllDay
        )
    }

    private func focusSession(start: Date, duration: Int) -> NextSessionFocusSessionSnapshot {
        NextSessionFocusSessionSnapshot(
            startTime: start,
            durationSeconds: duration,
            sessionType: .focus
        )
    }

    private func date(hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.calendar = Calendar.current
        components.year = 2026
        components.month = 6
        components.day = 28
        components.hour = hour
        components.minute = minute

        return components.date!
    }
}
