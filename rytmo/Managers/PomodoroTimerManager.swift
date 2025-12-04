//
//  PomodoroTimerManager.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import Foundation
import Combine

// MARK: - Pomodoro Timer Manager

/// 포모도로 타이머 비즈니스 로직 관리
class PomodoroTimerManager: ObservableObject {

    // MARK: - Published Properties

    @Published var session: PomodoroSession
    @Published var menuBarTitle: String = ""

    // MARK: - Private Properties

    private var timer: Timer?
    private var settings: PomodoroSettings

    // MARK: - Initialization

    init(settings: PomodoroSettings) {
        self.settings = settings
        self.session = PomodoroSession()
    }

    // MARK: - Public Methods

    /// 타이머 시작
    func start() {
        guard !session.isRunning else { return }

        // 첫 시작이면 집중 상태로 전환
        if session.state == .idle {
            session.moveToNextState(settings: settings)
        }

        // 종료 시간 계산 (백그라운드 동작 대비)
        session.endDate = Date().addingTimeInterval(session.remainingTime)
        session.isRunning = true

        // 타이머 시작 (매초 업데이트)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }

        updateMenuBarTitle()
    }

    /// 타이머 일시정지
    func pause() {
        guard session.isRunning else { return }

        session.isRunning = false
        session.endDate = nil
        timer?.invalidate()
        timer = nil

        updateMenuBarTitle()
    }

    /// 타이머 스킵 (다음 단계로)
    func skip() {
        // 현재 타이머 중지
        timer?.invalidate()
        timer = nil

        // 다음 상태로 전환
        session.moveToNextState(settings: settings)
        session.endDate = nil

        // 자동 시작하지 않음
        session.isRunning = false

        start()
    }

    /// 타이머 리셋
    func reset() {
        timer?.invalidate()
        timer = nil
        session.reset()
        updateMenuBarTitle()
    }

    // MARK: - Private Methods

    /// 매초 호출되는 틱 메서드
    private func tick() {
        // 백그라운드에서도 정확한 시간 계산
        if let endDate = session.endDate {
            let now = Date()
            session.remainingTime = max(0, endDate.timeIntervalSince(now))
        } else {
            session.remainingTime = max(0, session.remainingTime - 1)
        }

        // 타이머 종료
        if session.remainingTime <= 0 {
            timerDidFinish()
        }

        updateMenuBarTitle()
    }

    /// 타이머 종료 처리
    private func timerDidFinish() {
        timer?.invalidate()
        timer = nil

        session.isRunning = false
        session.endDate = nil

        // 다음 상태로 전환
        session.moveToNextState(settings: settings)

        // 자동으로 다음 상태 시작
        start()
    }

    /// 메뉴바 타이틀 업데이트
    private func updateMenuBarTitle() {
        let time = session.formattedTime

        if session.isRunning {
            menuBarTitle = time
        } else if session.state == .idle {
            menuBarTitle = ""
        } else {
            menuBarTitle = time
        }
    }
}
