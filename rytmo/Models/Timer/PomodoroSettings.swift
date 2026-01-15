//
//  PomodoroSettings.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import Foundation
import Combine

// MARK: - Pomodoro Settings

// MARK: - Pomodoro Settings Protocol

/// Protocol for Pomodoro Settings to allow mocking in tests
protocol PomodoroSettingsProtocol {
    var sessionsBeforeLongBreak: Int { get }
    func focusDurationInSeconds() -> TimeInterval
    func shortBreakDurationInSeconds() -> TimeInterval
    func longBreakDurationInSeconds() -> TimeInterval
}

/// Pomodoro Timer Settings
class PomodoroSettings: ObservableObject, PomodoroSettingsProtocol {

    // MARK: - Published Properties

    /// Focus Time (minutes)
    @Published var focusDuration: Int {
        didSet {
            UserDefaults.standard.set(focusDuration, forKey: "focusDuration")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "focus_duration",
                newValue: focusDuration
            )
        }
    }

    /// Short Break Time (minutes)
    @Published var shortBreakDuration: Int {
        didSet {
            UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "short_break_duration",
                newValue: shortBreakDuration
            )
        }
    }

    /// Long Break Time (minutes)
    @Published var longBreakDuration: Int {
        didSet {
            UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "long_break_duration",
                newValue: longBreakDuration
            )
        }
    }

    /// Number of sessions until Long Break
    @Published var sessionsBeforeLongBreak: Int {
        didSet {
            UserDefaults.standard.set(sessionsBeforeLongBreak, forKey: "sessionsBeforeLongBreak")
            AmplitudeManager.shared.trackSettingChanged(
                settingName: "sessions_before_long_break",
                newValue: sessionsBeforeLongBreak
            )
        }
    }

    /// Notification Enabled Status
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
        // Load values from UserDefaults (use default values)
        self.focusDuration = UserDefaults.standard.object(forKey: "focusDuration") as? Int ?? 25
        self.shortBreakDuration = UserDefaults.standard.object(forKey: "shortBreakDuration") as? Int ?? 5
        self.longBreakDuration = UserDefaults.standard.object(forKey: "longBreakDuration") as? Int ?? 15
        self.sessionsBeforeLongBreak = UserDefaults.standard.object(forKey: "sessionsBeforeLongBreak") as? Int ?? 4
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
    }

    // MARK: - Helper Methods

    /// Reset to defaults
    func resetToDefaults() {
        focusDuration = 25
        shortBreakDuration = 5
        longBreakDuration = 15
        sessionsBeforeLongBreak = 4
        notificationsEnabled = true

        // Event Tracking
        AmplitudeManager.shared.track(eventName: "settings_reset_to_defaults")
    }

    /// Convert to TimeInterval (in seconds)
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
