import Foundation

struct NextSessionRecommendationEngine {
    private let focusBuffer: TimeInterval = 5 * 60
    private let immediateEventThreshold: TimeInterval = 15 * 60
    private let brokenRhythmLookback: TimeInterval = 4 * 60 * 60
    private let brokenRhythmShortSessionRatio = 0.5
    private let wrapUpHour = 17

    func recommend(from input: NextSessionRecommendationInput) -> NextSessionRecommendation? {
        guard input.allowsRecommendation else {
            return nil
        }

        if let nextEvent = nextTimedEvent(from: input.upcomingEvents, now: input.now) {
            let secondsUntilEvent = max(0, nextEvent.startDate.timeIntervalSince(input.now))

            if secondsUntilEvent <= immediateEventThreshold && isWrapUpTime(input.now) {
                return NextSessionRecommendation(
                    sessionType: .wrapUp,
                    reason: .upcomingEventAtEndOfDay(minutesUntilEvent: minutes(from: secondsUntilEvent))
                )
            }

            if secondsUntilEvent < input.focusDuration + focusBuffer {
                return NextSessionRecommendation(
                    sessionType: .shortReset,
                    reason: .upcomingEventSoon(minutesUntilEvent: minutes(from: secondsUntilEvent))
                )
            }

            return NextSessionRecommendation(
                sessionType: .focus,
                reason: .enoughTimeBeforeEvent(minutesUntilEvent: minutes(from: secondsUntilEvent))
            )
        }

        if hasBrokenRhythm(input.recentSessions, now: input.now, focusDuration: input.focusDuration) {
            return NextSessionRecommendation(sessionType: .shortReset, reason: .recentShortSessions)
        }

        if isWrapUpTime(input.now) {
            return NextSessionRecommendation(sessionType: .wrapUp, reason: .endOfDay)
        }

        let dueSoonCount = activeDueSoonTodoCount(input.activeTodos, now: input.now)
        if dueSoonCount > 0 {
            return NextSessionRecommendation(sessionType: .focus, reason: .dueTodos(count: dueSoonCount))
        }

        return NextSessionRecommendation(sessionType: .focus, reason: .idleReady)
    }

    private func nextTimedEvent(
        from events: [NextSessionCalendarEvent],
        now: Date
    ) -> NextSessionCalendarEvent? {
        events
            .filter { event in
                guard event.isAllDay == false else { return false }
                if let endDate = event.endDate, endDate <= now {
                    return false
                }
                return event.startDate > now
            }
            .min { $0.startDate < $1.startDate }
    }

    private func hasBrokenRhythm(
        _ sessions: [NextSessionFocusSessionSnapshot],
        now: Date,
        focusDuration: TimeInterval
    ) -> Bool {
        let cutoff = now.addingTimeInterval(-brokenRhythmLookback)
        let shortSessionLimit = Int(focusDuration * brokenRhythmShortSessionRatio)

        var shortRecentFocusSessionCount = 0

        for session in sessions where session.sessionType == .focus &&
                session.startTime >= cutoff &&
                session.startTime <= now &&
                session.durationSeconds < shortSessionLimit {
            shortRecentFocusSessionCount += 1
            if shortRecentFocusSessionCount >= 2 {
                return true
            }
        }

        return false
    }

    private func activeDueSoonTodoCount(_ todos: [NextSessionTodoSnapshot], now: Date) -> Int {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return 0
        }

        var count = 0
        for todo in todos {
            guard let dueDate = todo.dueDate else { continue }
            if dueDate < tomorrow {
                count += 1
            }
        }
        return count
    }

    private func isWrapUpTime(_ date: Date) -> Bool {
        Calendar.current.component(.hour, from: date) >= wrapUpHour
    }

    private func minutes(from interval: TimeInterval) -> Int {
        max(0, Int(ceil(interval / 60)))
    }
}
