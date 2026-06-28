import Foundation

enum NextSessionType: String, CaseIterable, Equatable {
    case focus
    case shortReset
    case wrapUp

    var displayName: String {
        switch self {
        case .focus:
            return "Focus"
        case .shortReset:
            return "Short Reset"
        case .wrapUp:
            return "Wrap-up"
        }
    }
}

enum NextSessionReason: Equatable {
    case idleReady
    case enoughTimeBeforeEvent(minutesUntilEvent: Int)
    case upcomingEventSoon(minutesUntilEvent: Int)
    case upcomingEventAtEndOfDay(minutesUntilEvent: Int)
    case recentShortSessions
    case endOfDay
    case dueTodos(count: Int)

    var text: String {
        switch self {
        case .idleReady:
            return "You are idle and ready for a focus block."
        case .enoughTimeBeforeEvent(let minutesUntilEvent):
            return "You have about \(minutesUntilEvent) minutes before your next event."
        case .upcomingEventSoon(let minutesUntilEvent):
            return "A full focus block is tight with an event in about \(minutesUntilEvent) minutes."
        case .upcomingEventAtEndOfDay(let minutesUntilEvent):
            return "You have an event in about \(minutesUntilEvent) minutes, so closing loops fits better."
        case .recentShortSessions:
            return "Recent short focus attempts suggest restarting gently."
        case .endOfDay:
            return "It is late enough to close loops before starting another full block."
        case .dueTodos(let count):
            let noun = count == 1 ? "task" : "tasks"
            return "You have \(count) active \(noun) due soon, so a focus block fits."
        }
    }
}

struct NextSessionRecommendation: Equatable {
    let sessionType: NextSessionType
    let reason: NextSessionReason

    var title: String {
        sessionType.displayName
    }

    var reasonText: String {
        reason.text
    }

    var canStartFocusTimer: Bool {
        sessionType == .focus
    }
}

struct NextSessionRecommendationInput {
    let now: Date
    let allowsRecommendation: Bool
    let focusDuration: TimeInterval
    let upcomingEvents: [NextSessionCalendarEvent]
    let recentSessions: [NextSessionFocusSessionSnapshot]
    let activeTodos: [NextSessionTodoSnapshot]
}

struct NextSessionCalendarEvent: Equatable {
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
}

struct NextSessionFocusSessionSnapshot: Equatable {
    let startTime: Date
    let durationSeconds: Int
    let sessionType: SessionType
}

struct NextSessionTodoSnapshot: Equatable {
    let dueDate: Date?
}
