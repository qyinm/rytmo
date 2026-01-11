//
//  FocusStatsView.swift
//  rytmo
//
//  Created by hippoo on 1/11/26.
//

import SwiftUI
import SwiftData

struct FocusStatsView: View {
    @Query private var allSessions: [FocusSession]
    
    private var todaySessions: [FocusSession] {
        allSessions.filter { $0.isToday && $0.sessionType == .focus }
    }
    
    private var todayPomos: Int {
        todaySessions.count
    }
    
    private var todayFocusSeconds: Int {
        todaySessions.reduce(0) { $0 + $1.durationSeconds }
    }
    
    private var totalPomos: Int {
        allSessions.filter { $0.sessionType == .focus }.count
    }
    
    private var totalFocusSeconds: Int {
        allSessions.filter { $0.sessionType == .focus }.reduce(0) { $0 + $1.durationSeconds }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Today's Pomos",
                    value: "\(todayPomos)",
                    unit: nil
                )
                
                StatCard(
                    title: "Today's Focus",
                    value: formatTime(seconds: todayFocusSeconds).value,
                    unit: formatTime(seconds: todayFocusSeconds).unit
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Pomos",
                    value: "\(totalPomos)",
                    unit: nil
                )
                
                StatCard(
                    title: "Total Focus",
                    value: formatTotalTime(seconds: totalFocusSeconds).value,
                    unit: formatTotalTime(seconds: totalFocusSeconds).unit
                )
            }
        }
    }
    
    private func formatTime(seconds: Int) -> (value: String, unit: String?) {
        let minutes = seconds / 60
        if minutes < 60 {
            return ("\(minutes)", "m")
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return ("\(hours)h \(mins)", "m")
        }
    }
    
    private func formatTotalTime(seconds: Int) -> (value: String, unit: String?) {
        let minutes = seconds / 60
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours == 0 {
            return ("\(mins)", "m")
        } else {
            return ("\(hours)h \(mins)", "m")
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    FocusStatsView()
        .modelContainer(for: FocusSession.self, inMemory: true)
        .frame(width: 400)
        .padding()
}
