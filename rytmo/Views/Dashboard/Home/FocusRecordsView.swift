//
//  FocusRecordsView.swift
//  rytmo
//
//  Created by hippoo on 1/11/26.
//

import SwiftUI
import SwiftData

struct FocusRecordsView: View {
    @Query(
        filter: #Predicate<FocusSession> { $0.typeString == "FOCUS" },
        sort: \FocusSession.startTime,
        order: .reverse
    ) private var focusSessions: [FocusSession]

    private static let maxDaysToShow = 7
    private static let maxSessionsPerDay = 5
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    private var groupedSessions: [(Date, [FocusSession])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: focusSessions) { session -> Date in
            calendar.startOfDay(for: session.startTime)
        }

        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Focus Records")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            if focusSessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedSessions.prefix(Self.maxDaysToShow), id: \.0) { date, sessions in
                            dateSection(date: date, sessions: sessions)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No records yet")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            Text("Complete a focus session to see your history")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Date Section
    
    private func dateSection(date: Date, sessions: [FocusSession]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Self.dateFormatter.string(from: date))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            ForEach(sessions.prefix(Self.maxSessionsPerDay)) { session in
                sessionRow(session: session)
            }
            
            if sessions.count > Self.maxSessionsPerDay {
                Text("+ \(sessions.count - Self.maxSessionsPerDay) more")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 28)
            }
        }
    }
    
    // MARK: - Session Row

    private func sessionRow(session: FocusSession) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color(for: session.sessionType).opacity(0.8))
                .frame(width: 8, height: 8)
            
            Text(formatTimeRange(session: session))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(formatDuration(seconds: session.durationSeconds))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Formatters

    private func color(for type: SessionType) -> Color {
        switch type {
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    private func formatTimeRange(session: FocusSession) -> String {
        let start = Self.timeFormatter.string(from: session.startTime)
        let end = Self.timeFormatter.string(from: session.endTime)
        return "\(start) - \(end)"
    }
    
    private func formatDuration(seconds: Int) -> String {
        Self.durationFormatter.string(from: TimeInterval(seconds)) ?? "0m"
    }
}

#Preview {
    FocusRecordsView()
        .modelContainer(for: FocusSession.self, inMemory: true)
        .frame(width: 400, height: 400)
        .padding()
}
