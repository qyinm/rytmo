//
//  PomodoroSettingsTests.swift
//  rytmoTests
//
//  Unit tests for PomodoroSettings class
//

import XCTest
@testable import rytmo

final class PomodoroSettingsTests: XCTestCase {
    
    var settings: PomodoroSettings!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "focusDuration")
        defaults.removeObject(forKey: "shortBreakDuration")
        defaults.removeObject(forKey: "longBreakDuration")
        defaults.removeObject(forKey: "sessionsBeforeLongBreak")
        defaults.removeObject(forKey: "notificationsEnabled")
        
        settings = PomodoroSettings()
    }
    
    override func tearDown() {
        settings = nil
        super.tearDown()
    }
    
    // MARK: - Default Values Tests
    
    func testDefaultValues() {
        XCTAssertEqual(settings.focusDuration, 25)
        XCTAssertEqual(settings.shortBreakDuration, 5)
        XCTAssertEqual(settings.longBreakDuration, 15)
        XCTAssertEqual(settings.sessionsBeforeLongBreak, 4)
        XCTAssertTrue(settings.notificationsEnabled)
    }
    
    // MARK: - Duration Conversion Tests
    
    func testFocusDurationInSeconds() {
        settings.focusDuration = 25
        XCTAssertEqual(settings.focusDurationInSeconds(), 1500)
    }
    
    func testFocusDurationInSeconds_Custom() {
        settings.focusDuration = 50
        XCTAssertEqual(settings.focusDurationInSeconds(), 3000)
    }
    
    func testShortBreakDurationInSeconds() {
        settings.shortBreakDuration = 5
        XCTAssertEqual(settings.shortBreakDurationInSeconds(), 300)
    }
    
    func testShortBreakDurationInSeconds_Custom() {
        settings.shortBreakDuration = 10
        XCTAssertEqual(settings.shortBreakDurationInSeconds(), 600)
    }
    
    func testLongBreakDurationInSeconds() {
        settings.longBreakDuration = 15
        XCTAssertEqual(settings.longBreakDurationInSeconds(), 900)
    }
    
    func testLongBreakDurationInSeconds_Custom() {
        settings.longBreakDuration = 30
        XCTAssertEqual(settings.longBreakDurationInSeconds(), 1800)
    }
    
    // MARK: - resetToDefaults Tests
    
    func testResetToDefaults() {
        // Given: Modified settings
        settings.focusDuration = 50
        settings.shortBreakDuration = 10
        settings.longBreakDuration = 30
        settings.sessionsBeforeLongBreak = 6
        settings.notificationsEnabled = false
        
        // When
        settings.resetToDefaults()
        
        // Then
        XCTAssertEqual(settings.focusDuration, 25)
        XCTAssertEqual(settings.shortBreakDuration, 5)
        XCTAssertEqual(settings.longBreakDuration, 15)
        XCTAssertEqual(settings.sessionsBeforeLongBreak, 4)
        XCTAssertTrue(settings.notificationsEnabled)
    }
    
    // MARK: - Persistence Tests
    
    func testFocusDuration_PersistsToUserDefaults() {
        settings.focusDuration = 45
        
        let storedValue = UserDefaults.standard.integer(forKey: "focusDuration")
        XCTAssertEqual(storedValue, 45)
    }
    
    func testShortBreakDuration_PersistsToUserDefaults() {
        settings.shortBreakDuration = 8
        
        let storedValue = UserDefaults.standard.integer(forKey: "shortBreakDuration")
        XCTAssertEqual(storedValue, 8)
    }
    
    func testLongBreakDuration_PersistsToUserDefaults() {
        settings.longBreakDuration = 20
        
        let storedValue = UserDefaults.standard.integer(forKey: "longBreakDuration")
        XCTAssertEqual(storedValue, 20)
    }
}
