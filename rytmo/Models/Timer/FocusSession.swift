//
//  FocusSession.swift
//  rytmo
//
//  Created by hippoo on 1/11/26.
//

import Foundation
import SwiftData

/// Session type for focus/break sessions
enum SessionType: String, Codable, CaseIterable {
    case focus = "FOCUS"
    case shortBreak = "SHORT_BREAK"
    case longBreak = "LONG_BREAK"
    
    var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
    
    var color: String {
        switch self {
        case .focus: return "focus"
        case .shortBreak: return "shortBreak"
        case .longBreak: return "longBreak"
        }
    }
}

/// SwiftData model for persisting focus/break sessions
@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date
    var durationSeconds: Int
    var typeString: String
    var isSynced: Bool
    var updatedAt: Date
    
    var sessionType: SessionType {
        get {
            guard let type = SessionType(rawValue: typeString) else {
                assertionFailure("Invalid typeString: \(typeString)")
                return .focus
            }
            return type
        }
        set { typeString = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        durationSeconds: Int,
        sessionType: SessionType,
        isSynced: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime ?? startTime.addingTimeInterval(TimeInterval(durationSeconds))
        self.durationSeconds = durationSeconds
        self.typeString = sessionType.rawValue
        self.isSynced = isSynced
        self.updatedAt = Date()
    }
}

// MARK: - Helpers

extension FocusSession {
    private static let secondsInDay: Double = 86400.0 // 24 * 60 * 60

    /// Check if session is from today
    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }
    
    /// Get hour of day (0-23) for timeline positioning
    var startHour: Int {
        Calendar.current.component(.hour, from: startTime)
    }
    
    /// Get minute of hour (0-59)
    var startMinute: Int {
        Calendar.current.component(.minute, from: startTime)
    }
    
    /// Duration in minutes
    var durationMinutes: Double {
        Double(durationSeconds) / 60.0
    }
    
    /// Start position as fraction of day (0.0 - 1.0)
    var dayFraction: Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startTime)
        let secondsFromStartOfDay = startTime.timeIntervalSince(startOfDay)
        return secondsFromStartOfDay / Self.secondsInDay
    }

    /// Duration as fraction of day (0.0 - 1.0)
    var durationFraction: Double {
        Double(durationSeconds) / Self.secondsInDay
    }
}
