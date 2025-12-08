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
                // 상단 헤더: 대시보드 및 설정
                HStack(spacing: 16) {
                    Spacer()
                    
                    Button(action: {
                        openWindow(id: "main")
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("대시보드 열기")
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("설정")
                }
                
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
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 16) {
                Image("RytmoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
                    .padding(.top, 24)

                VStack(spacing: 6) {
                    Text("Rytmo")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("로그인이 필요합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)

            // 로그인 버튼들
            VStack(spacing: 10) {
                // Google 로그인 버튼
                Button(action: {
                    Task {
                        await authManager.signInWithGoogle()
                    }
                }) {
                    HStack(spacing: 8) {
                        if authManager.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "g.circle.fill")
                                .font(.caption)
                        }
                        Text(authManager.isLoading ? "로그인 중..." : "Google로 계속하기")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .foregroundStyle(.primary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                // 구분선
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                    Text("또는")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                }

                // 익명 로그인 버튼
                Button(action: {
                    Task {
                        await authManager.signInAnonymously()
                    }
                }) {
                    HStack(spacing: 8) {
                        if authManager.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                        }
                        Text(authManager.isLoading ? "로그인 중..." : "익명으로 시작하기")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.black)
                    .foregroundStyle(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                Text("익명 로그인은 데이터가 저장되지 않습니다")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)

            // 에러 메시지
            if let errorMessage = authManager.errorMessage {
                VStack {
                    Divider()
                        .padding(.vertical, 12)

                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption2)

                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            // 종료 버튼
            Divider()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.caption2)
                    Text("종료")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
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
