//
//  TimerStateTests.swift
//  rytmoTests
//
//  Unit tests for TimerState enum
//

import XCTest
@testable import rytmo

@MainActor
final class TimerStateTests: XCTestCase {
    
    // MARK: - displayName Tests
    
    func testDisplayName_Idle() {
        XCTAssertEqual(TimerState.idle.displayName, "Idle")
    }
    
    func testDisplayName_Focus() {
        XCTAssertEqual(TimerState.focus.displayName, "Focus")
    }
    
    func testDisplayName_ShortBreak() {
        XCTAssertEqual(TimerState.shortBreak.displayName, "Short Break")
    }
    
    func testDisplayName_LongBreak() {
        XCTAssertEqual(TimerState.longBreak.displayName, "Long Break")
    }
    
    // MARK: - defaultDuration Tests
    
    func testDefaultDuration_Idle() {
        XCTAssertEqual(TimerState.idle.defaultDuration, 0)
    }
    
    func testDefaultDuration_Focus() {
        XCTAssertEqual(TimerState.focus.defaultDuration, 25 * 60)
    }
    
    func testDefaultDuration_ShortBreak() {
        XCTAssertEqual(TimerState.shortBreak.defaultDuration, 5 * 60)
    }
    
    func testDefaultDuration_LongBreak() {
        XCTAssertEqual(TimerState.longBreak.defaultDuration, 15 * 60)
    }
}
