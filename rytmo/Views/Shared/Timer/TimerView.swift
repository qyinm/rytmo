//
//  TimerView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI

// MARK: - Timer View

/// 타이머 디스플레이 (원형 프로그레스 바)
struct TimerView: View {

    @EnvironmentObject var timerManager: PomodoroTimerManager

    var body: some View {
        VStack(spacing: 12) {
            // 원형 프로그레스 바
            ZStack {
                // 배경 원
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: 10
                    )
                    .frame(width: 160, height: 160)

                // 진행률 원
                Circle()
                    .trim(from: 0, to: timerManager.session.progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: 10,
                            lineCap: .round
                        )
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerManager.session.progress)

                // 중앙 텍스트
                VStack(spacing: 6) {
                    Text(timerManager.session.formattedTime)
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)

                    Text(timerManager.session.state.displayName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            // 세션 카운터
            if timerManager.session.state == .focus || timerManager.session.sessionCount > 0 {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < timerManager.session.sessionCount ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Private Computed Properties

    /// 상태별 프로그레스 색상
    private var progressColor: Color {
        switch timerManager.session.state {
        case .idle:
            return .gray
        case .focus:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    let settings = PomodoroSettings()
    let manager = PomodoroTimerManager(settings: settings)
    manager.session.state = .focus
    manager.session.remainingTime = 25 * 60
    manager.session.totalDuration = 25 * 60

    return TimerView()
        .environmentObject(manager)
}
