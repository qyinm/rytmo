//
//  PomodoroTimerManager.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import Foundation
import Combine
import UserNotifications

// MARK: - Pomodoro Timer Manager

/// Pomodoro Timer Business Logic Management
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

    /// Start Timer
    func start() {
        guard !session.isRunning else { return }

        // Switch to focus state if starting for the first time
        if session.state == .idle {
            session.moveToNextState(settings: settings)
        }

        // Calculate end time (for background operation)
        session.endDate = Date().addingTimeInterval(session.remainingTime)
        session.isRunning = true

        // Start timer (Update every second)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }

        updateMenuBarTitle()

        // Event Tracking
        AmplitudeManager.shared.trackTimerStarted(
            sessionType: session.state.displayName,
            duration: Int(session.totalDuration)
        )
    }

    /// Pause Timer
    func pause() {
        guard session.isRunning else { return }

        // Event Tracking (Called before pause)
        AmplitudeManager.shared.trackTimerPaused(
            sessionType: session.state.displayName,
            remainingTime: Int(session.remainingTime)
        )

        session.isRunning = false
        session.endDate = nil
        timer?.invalidate()
        timer = nil

        updateMenuBarTitle()
    }

    /// Skip Timer (to next step)
    func skip() {
        // Event Tracking (Called before skip)
        AmplitudeManager.shared.trackTimerSkipped(
            sessionType: session.state.displayName,
            remainingTime: Int(session.remainingTime)
        )

        // Stop current timer
        timer?.invalidate()
        timer = nil

        // Switch to next state
        session.moveToNextState(settings: settings)
        session.endDate = nil

        // Do not auto-start
        session.isRunning = false

        start()
    }

    /// Reset Timer
    func reset() {
        timer?.invalidate()
        timer = nil
        session.reset()
        updateMenuBarTitle()
    }

    // MARK: - Private Methods

    /// Tick method called every second
    private func tick() {
        // Accurate time calculation even in background
        if let endDate = session.endDate {
            let now = Date()
            session.remainingTime = max(0, endDate.timeIntervalSince(now))
        } else {
            session.remainingTime = max(0, session.remainingTime - 1)
        }

        // Timer finished
        if session.remainingTime <= 0 {
            timerDidFinish()
        }

        updateMenuBarTitle()
    }

    /// Timer termination processing
    private func timerDidFinish() {
        // Event Tracking (Called before state change)
        AmplitudeManager.shared.trackTimerCompleted(
            sessionType: session.state.displayName,
            duration: Int(session.totalDuration)
        )

        timer?.invalidate()
        timer = nil

        session.isRunning = false
        session.endDate = nil

        // Switch to next state
        session.moveToNextState(settings: settings)

        // Send state change notification
        sendStateChangeNotification()

        // Automatically start next state
        start()
    }

    /// Update Menubar Title
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

    /// Send state change notification
    private func sendStateChangeNotification() {
        // Do not send if notifications are disabled
        guard settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()

        switch session.state {
        case .idle:
            return // Do not send notifications in idle state
        case .focus:
            content.title = "Focus Time"
            content.body = "Focus time started (\(Int(session.totalDuration / 60))min)"
        case .shortBreak:
            content.title = "Short Break"
            content.body = "It's time for a short break (\(Int(session.totalDuration / 60))min)"
        case .longBreak:
            content.title = "Long Break"
            content.body = "It's time for a long break (\(Int(session.totalDuration / 60))min)"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Send immediately
        )

        UNUserNotificationCenter.current().add(request)
    }
}
