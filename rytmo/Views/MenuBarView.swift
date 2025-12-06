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
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openWindow) var openWindow

    @State private var showingSettings: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if authManager.isLoggedIn {
                // 로그인됨: 기존 기능 표시
                if showingSettings {
                    settingsContent
                } else {
                    timerContent
                }
            } else {
                // 로그인 안됨: 로그인 UI 표시
                loginContent
            }
        }
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true) // 핵심: 세로 길이를 내용물 크기에 고정
    }

    // MARK: - Timer Content

    private var timerContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 타이머 디스플레이
                TimerView()

                // 타이머 컨트롤 버튼
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

                // Music 섹션
                MusicSectionView()

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
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        SettingsView(onDismiss: {
            showingSettings = false
        })
    }

    // MARK: - Login Content

    private var loginContent: some View {
        VStack(spacing: 20) {
            // 앱 아이콘
            Image(systemName: "timer")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
                .padding(.top, 20)

            // 타이틀
            VStack(spacing: 8) {
                Text("Rytmo")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("로그인이 필요합니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 8)

            // 로그인 버튼들
            VStack(spacing: 12) {
                // Google 로그인 버튼
                Button(action: {
                    Task {
                        await authManager.signInWithGoogle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.title3)
                        Text("Google로 계속하기")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white)
                    .foregroundStyle(.black)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                // 구분선
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("또는")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal)

                // 익명 로그인 버튼
                Button(action: {
                    Task {
                        await authManager.signInAnonymously()
                    }
                }) {
                    HStack(spacing: 8) {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "person.fill.questionmark")
                                .font(.title3)
                        }
                        Text(authManager.isLoading ? "로그인 중..." : "익명으로 시작하기")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)
            }

            // 에러 메시지
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()

            // 종료 버튼
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("종료")
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .padding(.bottom, 12)
        }
        .padding()
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
        .environmentObject(MusicPlayerManager())
}
