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
        VStack(spacing: 20) {
            // 원형 프로그레스 바
            ZStack {
                // 배경 원
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: 12
                    )
                    .frame(width: 200, height: 200)

                // 진행률 원
                Circle()
                    .trim(from: 0, to: timerManager.session.progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerManager.session.progress)

                // 중앙 텍스트
                VStack(spacing: 8) {
                    Text(timerManager.session.state.emoji)
                        .font(.system(size: 40))

                    Text(timerManager.session.formattedTime)
                        .font(.system(size: 36, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)

                    Text(timerManager.session.state.displayName)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            // 세션 카운터
            if timerManager.session.state == .focus || timerManager.session.sessionCount > 0 {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < timerManager.session.sessionCount ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding()
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
    TimerView()
        .environmentObject({
            let manager = PomodoroTimerManager()
            manager.session.state = .focus
            manager.session.remainingTime = 25 * 60
            return manager
        }())
}
