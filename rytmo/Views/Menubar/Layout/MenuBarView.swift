//
//  MenuBarView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI

// MARK: - Menu Bar View

/// Menu Bar Popover UI
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
                // Logged In: New Menu Bar UI
                if showingSettings {
                    settingsContent
                } else {
                    newMenuBarContent
                }
            } else {
                // Not Logged In: Show Login UI
                loginContent
            }
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }

    private struct Style {
        static let iconSize: CGFloat = 16
        static let headerSpacing: CGFloat = 16
    }

    private func headerButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Style.iconSize))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - New Menu Bar Content
    
    private var newMenuBarContent: some View {
        ScrollView {
            VStack(spacing: 12) {               
                // New Compact Timer
                MenuBarTimerView()
                
                Divider()
                
                // Todo List
                MenuBarTodoView()
                
                Divider()
                
                // New Compact Music Player
                MenuBarMusicView()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        MenuBarSettingsView(onDismiss: {
            showingSettings = false
        })
    }

    // MARK: - Login Content

    private var loginContent: some View {
        VStack(spacing: 0) {
            // Header
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

                    Text("Login Required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)

            // Login Buttons
            VStack(spacing: 10) {
                // Google Login Button
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
                        Text(authManager.isLoading ? "Logging in..." : "Continue with Google")
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

                // Divider
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                    Text("or")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                }

                // Anonymous Login Button
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
                        Text(authManager.isLoading ? "Logging in..." : "Start Anonymously")
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

                Text("Anonymous login data is not saved")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)

            // Error Message
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

            // Quit Button
            Divider()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.caption2)
                    Text("Quit")
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
