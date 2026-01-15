//
//  PomodoroSession.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import Foundation

// MARK: - Timer State

/// Timer State
enum TimerState {
    case idle           // Idle
    case focus          // Focus (25min)
    case shortBreak     // Short Break (5min)
    case longBreak      // Long Break (15min)

    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .focus:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    /// Default Duration (seconds)
    var defaultDuration: TimeInterval {
        switch self {
        case .idle:
            return 0
        case .focus:
            return 25 * 60  // 25 min
        case .shortBreak:
            return 5 * 60   // 5 min
        case .longBreak:
            return 15 * 60  // 15 min
        }
    }
}

// MARK: - Pomodoro Session

/// Pomodoro Session Data
struct PomodoroSession {
    var state: TimerState
    var isRunning: Bool
    var remainingTime: TimeInterval
    var totalDuration: TimeInterval  // Total duration of current session
    var sessionCount: Int  // Completed focus sessions count (0~3)
    var endDate: Date?     // Scheduled end time (for background calculation)

    init() {
        self.state = .idle
        self.isRunning = false
        self.remainingTime = 0
        self.totalDuration = 0
        self.sessionCount = 0
        self.endDate = nil
    }

    /// Progress (0.0 ~ 1.0)
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, (totalDuration - remainingTime) / totalDuration))
    }

    /// MM:SS format string
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Determine next state
    mutating func moveToNextState(settings: PomodoroSettingsProtocol) {
        switch state {
        case .idle:
            state = .focus
            sessionCount = 0
        case .focus:
            sessionCount += 1
            // Long break if set number of sessions completed, otherwise short break
            if sessionCount >= settings.sessionsBeforeLongBreak {
                state = .longBreak
                sessionCount = 0
            } else {
                state = .shortBreak
            }
        case .shortBreak, .longBreak:
            state = .focus
        }

        // Get time from settings
        switch state {
        case .idle:
            remainingTime = 0
            totalDuration = 0
        case .focus:
            remainingTime = settings.focusDurationInSeconds()
            totalDuration = remainingTime
        case .shortBreak:
            remainingTime = settings.shortBreakDurationInSeconds()
            totalDuration = remainingTime
        case .longBreak:
            remainingTime = settings.longBreakDurationInSeconds()
            totalDuration = remainingTime
        }
    }

    /// Reset Timer
    mutating func reset() {
        state = .idle
        isRunning = false
        remainingTime = 0
        totalDuration = 0
        sessionCount = 0
        endDate = nil
    }
}
