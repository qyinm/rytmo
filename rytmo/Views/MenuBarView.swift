//
//  MenuBarView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI

// MARK: - Menu Bar View

/// 메뉴바 팝오버 UI
struct MenuBarView: View {

    @EnvironmentObject var timerManager: PomodoroTimerManager
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(spacing: 20) {
            // 타이머 디스플레이
            TimerView()

            Divider()

            // 컨트롤 버튼
            HStack(spacing: 12) {
                // 시작/일시정지 버튼
                Button(action: {
                    if timerManager.session.isRunning {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                }) {
                    HStack {
                        Image(systemName: timerManager.session.isRunning ? "pause.fill" : "play.fill")
                        Text(timerManager.session.isRunning ? "일시정지" : "시작")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(timerManager.session.isRunning ? .orange : .blue)

                // 스킵 버튼
                Button(action: {
                    timerManager.skip()
                }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("스킵")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .disabled(timerManager.session.state == .idle)

                // 리셋 버튼
                Button(action: {
                    timerManager.reset()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.bordered)
                .disabled(timerManager.session.state == .idle && !timerManager.session.isRunning)
            }

            Divider()

            // 대시보드 열기 버튼
            Button(action: {
                openWindow(id: "main")
            }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("대시보드 열기")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)

            Divider()

            // 종료 버튼
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("종료")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
        }
        .padding()
        .frame(width: 360)
    }
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .environmentObject({
            let manager = PomodoroTimerManager()
            manager.session.state = .focus
            manager.session.remainingTime = 15 * 60
            return manager
        }())
}
