//
//  PomodoroSessionTests.swift
//  rytmoTests
//
//  Unit tests for PomodoroSession struct
//

import XCTest
@testable import rytmo

@MainActor
final class PomodoroSessionTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInit_DefaultValues() {
        let session = PomodoroSession()
        
        XCTAssertEqual(session.state, .idle)
        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.remainingTime, 0)
        XCTAssertEqual(session.totalDuration, 0)
        XCTAssertEqual(session.sessionCount, 0)
        XCTAssertNil(session.endDate)
    }
    
    // MARK: - Progress Tests
    
    func testProgress_ReturnsZeroWhenTotalDurationIsZero() {
        let session = PomodoroSession()
        XCTAssertEqual(session.progress, 0)
    }
    
    func testProgress_ReturnsZeroAtStart() {
        var session = PomodoroSession()
        session.totalDuration = 1500 // 25 min
        session.remainingTime = 1500
        
        XCTAssertEqual(session.progress, 0)
    }
    
    func testProgress_ReturnsFiftyPercentAtHalfway() {
        var session = PomodoroSession()
        session.totalDuration = 1500
        session.remainingTime = 750
        
        XCTAssertEqual(session.progress, 0.5, accuracy: 0.001)
    }
    
    func testProgress_ReturnsOneAtEnd() {
        var session = PomodoroSession()
        session.totalDuration = 1500
        session.remainingTime = 0
        
        XCTAssertEqual(session.progress, 1.0)
    }
    
    func testProgress_ClampsToOne() {
        var session = PomodoroSession()
        session.totalDuration = 1500
        session.remainingTime = -100 // Negative remaining
        
        XCTAssertEqual(session.progress, 1.0)
    }
    
    // MARK: - formattedTime Tests
    
    func testFormattedTime_ZeroSeconds() {
        var session = PomodoroSession()
        session.remainingTime = 0
        
        XCTAssertEqual(session.formattedTime, "00:00")
    }
    
    func testFormattedTime_25Minutes() {
        var session = PomodoroSession()
        session.remainingTime = 25 * 60
        
        XCTAssertEqual(session.formattedTime, "25:00")
    }
    
    func testFormattedTime_5Minutes30Seconds() {
        var session = PomodoroSession()
        session.remainingTime = 5 * 60 + 30
        
        XCTAssertEqual(session.formattedTime, "05:30")
    }
    
    func testFormattedTime_59Seconds() {
        var session = PomodoroSession()
        session.remainingTime = 59
        
        XCTAssertEqual(session.formattedTime, "00:59")
    }
    
    // MARK: - moveToNextState Tests
    
    func testMoveToNextState_IdleToFocus() {
        var session = PomodoroSession()
        let settings = createMockSettings()
        
        session.moveToNextState(settings: settings)
        
        XCTAssertEqual(session.state, .focus)
        XCTAssertEqual(session.sessionCount, 0)
        XCTAssertEqual(session.remainingTime, settings.focusDurationInSeconds())
    }
    
    func testMoveToNextState_FocusToShortBreak() {
        var session = PomodoroSession()
        let settings = createMockSettings()
        
        session.state = .focus
        session.sessionCount = 0
        
        session.moveToNextState(settings: settings)
        
        XCTAssertEqual(session.state, .shortBreak)
        XCTAssertEqual(session.sessionCount, 1)
    }
    
    func testMoveToNextState_FocusToLongBreakAfter4Sessions() {
        var session = PomodoroSession()
        let settings = createMockSettings()
        
        session.state = .focus
        session.sessionCount = 3 // Will become 4 after increment
        
        session.moveToNextState(settings: settings)
        
        XCTAssertEqual(session.state, .longBreak)
        XCTAssertEqual(session.sessionCount, 0) // Resets after long break
    }
    
    func testMoveToNextState_ShortBreakToFocus() {
        var session = PomodoroSession()
        let settings = createMockSettings()
        
        session.state = .shortBreak
        session.sessionCount = 2
        
        session.moveToNextState(settings: settings)
        
        XCTAssertEqual(session.state, .focus)
        XCTAssertEqual(session.sessionCount, 2) // Preserved
    }
    
    func testMoveToNextState_LongBreakToFocus() {
        var session = PomodoroSession()
        let settings = createMockSettings()
        
        session.state = .longBreak
        
        session.moveToNextState(settings: settings)
        
        XCTAssertEqual(session.state, .focus)
    }
    
    // MARK: - reset Tests
    
    func testReset_ResetsAllValues() {
        var session = PomodoroSession()
        session.state = .focus
        session.isRunning = true
        session.remainingTime = 1000
        session.totalDuration = 1500
        session.sessionCount = 3
        session.endDate = Date()
        
        session.reset()
        
        XCTAssertEqual(session.state, .idle)
        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.remainingTime, 0)
        XCTAssertEqual(session.totalDuration, 0)
        XCTAssertEqual(session.sessionCount, 0)
        XCTAssertNil(session.endDate)
    }
    
    // MARK: - Helpers
    
    struct MockPomodoroSettings: PomodoroSettingsProtocol {
        var sessionsBeforeLongBreak: Int = 4
        var focusDuration: Int = 25
        var shortBreakDuration: Int = 5
        var longBreakDuration: Int = 15
        
        func focusDurationInSeconds() -> TimeInterval {
            Double(focusDuration * 60)
        }
        
        func shortBreakDurationInSeconds() -> TimeInterval {
            Double(shortBreakDuration * 60)
        }
        
        func longBreakDurationInSeconds() -> TimeInterval {
            Double(longBreakDuration * 60)
        }
    }
    
    private func createMockSettings() -> MockPomodoroSettings {
        return MockPomodoroSettings()
    }
}

