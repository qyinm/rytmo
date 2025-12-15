//
//  PomodoroSettings.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import Foundation
import Combine

// MARK: - Pomodoro Settings

/// 포모도로 타이머 설정
class PomodoroSettings: ObservableObject {

    // MARK: - Published Properties

    /// 집중 시간 (분)
    @Published var focusDuration: Int {
        didSet {
            UserDefaults.standard.set(focusDuration, forKey: "focusDuration")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "focus_duration",
                newValue: focusDuration
            )
        }
    }

    /// 짧은 휴식 시간 (분)
    @Published var shortBreakDuration: Int {
        didSet {
            UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "short_break_duration",
                newValue: shortBreakDuration
            )
        }
    }

    /// 긴 휴식 시간 (분)
    @Published var longBreakDuration: Int {
        didSet {
            UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "long_break_duration",
                newValue: longBreakDuration
            )
        }
    }

    /// 긴 휴식 전 세션 수
    @Published var sessionsBeforeLongBreak: Int {
        didSet {
            UserDefaults.standard.set(sessionsBeforeLongBreak, forKey: "sessionsBeforeLongBreak")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "sessions_before_long_break",
                newValue: sessionsBeforeLongBreak
            )
        }
    }

    /// 알림 활성화 여부
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "notifications_enabled",
                newValue: notificationsEnabled
            )
        }
    }

    // MARK: - Initialization

    init() {
        // UserDefaults에서 값 불러오기 (기본값 사용)
        self.focusDuration = UserDefaults.standard.object(forKey: "focusDuration") as? Int ?? 25
        self.shortBreakDuration = UserDefaults.standard.object(forKey: "shortBreakDuration") as? Int ?? 5
        self.longBreakDuration = UserDefaults.standard.object(forKey: "longBreakDuration") as? Int ?? 15
        self.sessionsBeforeLongBreak = UserDefaults.standard.object(forKey: "sessionsBeforeLongBreak") as? Int ?? 4
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
    }

    // MARK: - Helper Methods

    /// 기본값으로 리셋
    func resetToDefaults() {
        focusDuration = 25
        shortBreakDuration = 5
        longBreakDuration = 15
        sessionsBeforeLongBreak = 4
        notificationsEnabled = true

        // 이벤트 트래킹
        AmplitudeManager.shared.track(eventName: "settings_reset_to_defaults")
    }

    /// TimeInterval로 변환 (초 단위)
    func focusDurationInSeconds() -> TimeInterval {
        return TimeInterval(focusDuration * 60)
    }

    func shortBreakDurationInSeconds() -> TimeInterval {
        return TimeInterval(shortBreakDuration * 60)
    }

    func longBreakDurationInSeconds() -> TimeInterval {
        return TimeInterval(longBreakDuration * 60)
    }
}
