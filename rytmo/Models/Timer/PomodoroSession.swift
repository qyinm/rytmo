//
//  PomodoroSession.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import Foundation

// MARK: - Timer State

/// 타이머 상태
enum TimerState {
    case idle           // 대기
    case focus          // 집중 (25분)
    case shortBreak     // 짧은 휴식 (5분)
    case longBreak      // 긴 휴식 (15분)

    var displayName: String {
        switch self {
        case .idle:
            return "대기"
        case .focus:
            return "집중"
        case .shortBreak:
            return "짧은 휴식"
        case .longBreak:
            return "긴 휴식"
        }
    }

    /// 기본 시간 (초)
    var defaultDuration: TimeInterval {
        switch self {
        case .idle:
            return 0
        case .focus:
            return 25 * 60  // 25분
        case .shortBreak:
            return 5 * 60   // 5분
        case .longBreak:
            return 15 * 60  // 15분
        }
    }
}

// MARK: - Pomodoro Session

/// 포모도로 세션 데이터
struct PomodoroSession {
    var state: TimerState
    var isRunning: Bool
    var remainingTime: TimeInterval
    var totalDuration: TimeInterval  // 현재 세션의 전체 시간
    var sessionCount: Int  // 완료된 집중 세션 수 (0~3)
    var endDate: Date?     // 타이머 종료 예정 시간 (백그라운드 계산용)

    init() {
        self.state = .idle
        self.isRunning = false
        self.remainingTime = 0
        self.totalDuration = 0
        self.sessionCount = 0
        self.endDate = nil
    }

    /// 진행률 (0.0 ~ 1.0)
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, (totalDuration - remainingTime) / totalDuration))
    }

    /// MM:SS 형식 문자열
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 다음 상태 결정
    mutating func moveToNextState(settings: PomodoroSettings) {
        switch state {
        case .idle:
            state = .focus
            sessionCount = 0
        case .focus:
            sessionCount += 1
            // 설정된 세트 수 완료 시 긴 휴식, 아니면 짧은 휴식
            if sessionCount >= settings.sessionsBeforeLongBreak {
                state = .longBreak
                sessionCount = 0
            } else {
                state = .shortBreak
            }
        case .shortBreak, .longBreak:
            state = .focus
        }

        // 설정에서 시간 가져오기
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

    /// 타이머 리셋
    mutating func reset() {
        state = .idle
        isRunning = false
        remainingTime = 0
        totalDuration = 0
        sessionCount = 0
        endDate = nil
    }
}
