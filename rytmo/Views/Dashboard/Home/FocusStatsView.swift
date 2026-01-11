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
    
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()
    
    private var stats: (todayPomos: Int, todaySeconds: Int, totalPomos: Int, totalSeconds: Int) {
        var todayPomos = 0
        var todaySeconds = 0
        var totalPomos = 0
        var totalSeconds = 0
        
        for session in allSessions where session.sessionType == .focus {
            totalPomos += 1
            totalSeconds += session.durationSeconds
            
            if session.isToday {
                todayPomos += 1
                todaySeconds += session.durationSeconds
            }
        }
        
        return (todayPomos, todaySeconds, totalPomos, totalSeconds)
    }
    
    var body: some View {
        let currentStats = stats
        
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Today's Pomos",
                    value: "\(currentStats.todayPomos)"
                )
                
                StatCard(
                    title: "Today's Focus",
                    value: formatDuration(seconds: currentStats.todaySeconds)
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Pomos",
                    value: "\(currentStats.totalPomos)"
                )
                
                StatCard(
                    title: "Total Focus",
                    value: formatDuration(seconds: currentStats.totalSeconds)
                )
            }
        }
    }
    
    private func formatDuration(seconds: Int) -> String {
        if seconds == 0 {
            return "0m"
        }
        return Self.durationFormatter.string(from: TimeInterval(seconds)) ?? "0m"
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
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
