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
    @EnvironmentObject var settings: PomodoroSettings
    @Environment(\.openWindow) var openWindow

    @State private var showingSettings: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if showingSettings {
                // 설정 뷰
                settingsContent
            } else {
                // 타이머 뷰
                timerContent
            }
        }
        .frame(width: 360)
    }

    // MARK: - Timer Content

    private var timerContent: some View {
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

            // 대시보드 및 설정 버튼
            HStack(spacing: 12) {
                Button(action: {
                    openWindow(id: "main")
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("대시보드")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("설정")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }

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
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button(action: {
                    showingSettings = false
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text("타이머 설정")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding()

            Divider()

            // 설정 항목
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // 집중 시간
                    SettingRow(
                        title: "집중 시간",
                        value: $settings.focusDuration,
                        range: 1...60,
                        unit: "분"
                    )

                    Divider()

                    // 짧은 휴식 시간
                    SettingRow(
                        title: "짧은 휴식",
                        value: $settings.shortBreakDuration,
                        range: 1...30,
                        unit: "분"
                    )

                    Divider()

                    // 긴 휴식 시간
                    SettingRow(
                        title: "긴 휴식",
                        value: $settings.longBreakDuration,
                        range: 5...60,
                        unit: "분"
                    )

                    Divider()

                    // 긴 휴식 전 세션 수
                    SettingRow(
                        title: "긴 휴식 전 세션 수",
                        value: $settings.sessionsBeforeLongBreak,
                        range: 2...10,
                        unit: "세트"
                    )
                }
                .padding()
            }

            Divider()

            // 하단 버튼
            Button(action: {
                settings.resetToDefaults()
            }) {
                Text("기본값 복원")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    let settings = PomodoroSettings()
    let manager = PomodoroTimerManager(settings: settings)
    manager.session.state = .focus
    manager.session.remainingTime = 15 * 60
    manager.session.totalDuration = 25 * 60

    return MenuBarView()
        .environmentObject(manager)
        .environmentObject(settings)
}
