//
//  AmplitudeManager.swift
//  rytmo
//
//  Created by hippoo on 12/5/25.
//

import Foundation
import AmplitudeUnified

/// Amplitude 분석 이벤트를 관리하는 싱글톤 클래스
class AmplitudeManager {

    // MARK: - Singleton

    static let shared = AmplitudeManager()

    private var amplitude: Amplitude?

    private init() {}

    // MARK: - Setup

    /// Amplitude 초기화
    /// - Parameter apiKey: Amplitude API 키
    func setup(apiKey: String) {
        // 로그 레벨 설정 (개발 중에는 debug, 프로덕션에서는 warn)
        #if DEBUG
        let logLevel = LogLevelEnum.DEBUG.rawValue
        #else
        let logLevel = LogLevelEnum.WARN.rawValue
        #endif

        // Analytics 구성 설정
        let analyticsConfig = AnalyticsConfig(
            flushQueueSize: 30,
            flushIntervalMillis: 30000,
            autocapture: [.sessions, .appLifecycles]
        )

        // Amplitude 인스턴스 생성
        // 참고: Session Replay는 iOS에서만 지원되며, macOS에서는 사용할 수 없습니다.
        amplitude = Amplitude(
            apiKey: apiKey,
            serverZone: .US,
            analyticsConfig: analyticsConfig,
            logger: ConsoleLogger(logLevel: logLevel)
        )

        // 초기 이벤트 전송
        trackAppLaunched()
    }

    // MARK: - Event Tracking

    /// 일반 이벤트 트래킹
    /// - Parameters:
    ///   - eventName: 이벤트 이름
    ///   - properties: 이벤트 속성 (선택사항)
    func track(eventName: String, properties: [String: Any]? = nil) {
        amplitude?.track(
            eventType: eventName,
            eventProperties: properties
        )
    }

    /// 사용자 속성 설정
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - properties: 사용자 속성
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

    /// 앱 시작 이벤트
    private func trackAppLaunched() {
        track(eventName: "app_launched", properties: [
            "platform": "macOS",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }

    /// 타이머 시작 이벤트
    /// - Parameters:
    ///   - sessionType: 세션 타입 (focus, short_break, long_break)
    ///   - duration: 세션 시간 (초)
    func trackTimerStarted(sessionType: String, duration: Int) {
        track(eventName: "timer_started", properties: [
            "session_type": sessionType,
            "duration_seconds": duration
        ])
    }

    /// 타이머 완료 이벤트
    /// - Parameters:
    ///   - sessionType: 세션 타입
    ///   - duration: 세션 시간 (초)
    func trackTimerCompleted(sessionType: String, duration: Int) {
        track(eventName: "timer_completed", properties: [
            "session_type": sessionType,
            "duration_seconds": duration
        ])
    }

    /// 타이머 일시정지 이벤트
    /// - Parameters:
    ///   - sessionType: 세션 타입
    ///   - remainingTime: 남은 시간 (초)
    func trackTimerPaused(sessionType: String, remainingTime: Int) {
        track(eventName: "timer_paused", properties: [
            "session_type": sessionType,
            "remaining_seconds": remainingTime
        ])
    }

    /// 타이머 스킵 이벤트
    /// - Parameters:
    ///   - sessionType: 세션 타입
    ///   - remainingTime: 남은 시간 (초)
    func trackTimerSkipped(sessionType: String, remainingTime: Int) {
        track(eventName: "timer_skipped", properties: [
            "session_type": sessionType,
            "remaining_seconds": remainingTime
        ])
    }

    /// 음악 재생 이벤트
    /// - Parameters:
    ///   - trackTitle: 트랙 제목
    ///   - playlistName: 플레이리스트 이름
    func trackMusicPlayed(trackTitle: String, playlistName: String?) {
        track(eventName: "music_played", properties: [
            "track_title": trackTitle,
            "playlist_name": playlistName ?? "none"
        ])
    }

    /// 음악 일시정지 이벤트
    func trackMusicPaused() {
        track(eventName: "music_paused")
    }

    /// 설정 변경 이벤트
    /// - Parameters:
    ///   - settingName: 설정 이름
    ///   - newValue: 새로운 값
    func trackSettingChanged(settingName: String, newValue: Any) {
        track(eventName: "setting_changed", properties: [
            "setting_name": settingName,
            "new_value": "\(newValue)"
        ])
    }
}
