//
//  AmplitudeManager.swift
//  rytmo
//
//  Created by hippoo on 12/5/25.
//

import Foundation
import AmplitudeUnified

/// Singleton class that manages Amplitude analytics events
class AmplitudeManager {

    // MARK: - Singleton

    static let shared = AmplitudeManager()

    private var amplitude: Amplitude?

    private init() {}

    // MARK: - Setup

    /// Initialize Amplitude
    /// - Parameter apiKey: Amplitude API Key
    func setup(apiKey: String) {
        // Log level setting (debug during development, warn in production)
        #if DEBUG
        let logLevel = LogLevelEnum.DEBUG.rawValue
        #else
        let logLevel = LogLevelEnum.WARN.rawValue
        #endif

        // Analytics configuration settings
        let analyticsConfig = AnalyticsConfig(
            flushQueueSize: 30,
            flushIntervalMillis: 30000,
            autocapture: [.sessions, .appLifecycles]
        )

        // Create Amplitude instance
        // Note: Session Replay is supported only on iOS, not available on macOS.
        amplitude = Amplitude(
            apiKey: apiKey,
            serverZone: .US,
            analyticsConfig: analyticsConfig,
            logger: ConsoleLogger(logLevel: logLevel)
        )

        // Send initial event
        trackAppLaunched()
    }

    // MARK: - Event Tracking

    /// Track generic event
    /// - Parameters:
    ///   - eventName: Event Name
    ///   - properties: Event Properties (Optional)
    func track(eventName: String, properties: [String: Any]? = nil) {
        amplitude?.track(
            eventType: eventName,
            eventProperties: properties
        )
    }

    /// Set user properties
    /// - Parameters:
    ///   - userId: User ID
    ///   - properties: User properties
    func identify(userId: String, properties: [String: Any]? = nil) {
        amplitude?.setUserId(userId: userId)

        if let properties = properties {
            let identify = Identify()
            for (key, value) in properties {
                identify.set(property: key, value: value)
            }
            amplitude?.identify(identify: identify)
        }
    }

    // MARK: - Predefined Events

    /// App Launch Event
    private func trackAppLaunched() {
        track(eventName: "app_launched", properties: [
            "platform": "macOS",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }

    /// Timer Started Event
    /// - Parameters:
    ///   - sessionType: Session Type (focus, short_break, long_break)
    ///   - duration: Session Duration (seconds)
    func trackTimerStarted(sessionType: String, duration: Int) {
        track(eventName: "timer_started", properties: [
            "session_type": sessionType,
            "duration_seconds": duration
        ])
    }

    /// Timer Completed Event
    /// - Parameters:
    ///   - sessionType: Session Type
    ///   - duration: Session Duration (seconds)
    func trackTimerCompleted(sessionType: String, duration: Int) {
        track(eventName: "timer_completed", properties: [
            "session_type": sessionType,
            "duration_seconds": duration
        ])
    }

    /// Timer Paused Event
    /// - Parameters:
    ///   - sessionType: Session Type
    ///   - remainingTime: Remaining Time (seconds)
    func trackTimerPaused(sessionType: String, remainingTime: Int) {
        track(eventName: "timer_paused", properties: [
            "session_type": sessionType,
            "remaining_seconds": remainingTime
        ])
    }

    /// Timer Skipped Event
    /// - Parameters:
    ///   - sessionType: Session Type
    ///   - remainingTime: Remaining Time (seconds)
    func trackTimerSkipped(sessionType: String, remainingTime: Int) {
        track(eventName: "timer_skipped", properties: [
            "session_type": sessionType,
            "remaining_seconds": remainingTime
        ])
    }

    /// Music Played Event
    /// - Parameters:
    ///   - trackTitle: Track Title
    ///   - playlistName: Playlist Name
    func trackMusicPlayed(trackTitle: String, playlistName: String?) {
        track(eventName: "music_played", properties: [
            "track_title": trackTitle,
            "playlist_name": playlistName ?? "none"
        ])
    }

    /// Music Paused Event
    func trackMusicPaused() {
        track(eventName: "music_paused")
    }

    /// Setting Changed Event
    /// - Parameters:
    ///   - settingName: Setting Name
    ///   - newValue: New Value
    func trackSettingChanged(settingName: String, newValue: Any) {
        track(eventName: "setting_changed", properties: [
            "setting_name": settingName,
            "new_value": "\(newValue)"
        ])
    }
}
