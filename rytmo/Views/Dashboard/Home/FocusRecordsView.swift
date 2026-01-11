//
//  FocusRecordsView.swift
//  rytmo
//
//  Created by hippoo on 1/11/26.
//

import SwiftUI
import SwiftData

struct FocusRecordsView: View {
    @Query(sort: \FocusSession.startTime, order: .reverse) private var allSessions: [FocusSession]
    
    private var groupedSessions: [(String, [FocusSession])] {
        let focusSessions = allSessions.filter { $0.sessionType == .focus }
        let grouped = Dictionary(grouping: focusSessions) { session -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 M월 d일"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: session.startTime)
        }
        
        return grouped.sorted { first, second in
            guard let firstSession = first.value.first,
                  let secondSession = second.value.first else { return false }
            return firstSession.startTime > secondSession.startTime
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Focus Records")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            if allSessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedSessions.prefix(7), id: \.0) { date, sessions in
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
    
    private func dateSection(date: String, sessions: [FocusSession]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            ForEach(sessions.prefix(5)) { session in
                sessionRow(session: session)
            }
            
            if sessions.count > 5 {
                Text("+ \(sessions.count - 5) more")
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
                .fill(Color.red.opacity(0.8))
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
    
    private func formatTimeRange(session: FocusSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let start = formatter.string(from: session.startTime)
        let end = formatter.string(from: session.endTime)
        
        return "\(start) - \(end)"
    }
    
    private func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

#Preview {
    FocusRecordsView()
        .modelContainer(for: FocusSession.self, inMemory: true)
        .frame(width: 400, height: 400)
        .padding()
}
