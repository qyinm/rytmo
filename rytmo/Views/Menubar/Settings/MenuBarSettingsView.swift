//
//  MenuBarSettingsView.swift
//  rytmo
//
//  Created by hippoo on 12/23/25.
//

import SwiftUI
import UserNotifications
import FirebaseAuth

// MARK: - Menu Bar Settings View
/// Compact Settings Screen for Menu Bar
struct MenuBarSettingsView: View {
    
    @EnvironmentObject var settings: PomodoroSettings
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openWindow) var openWindow
    
    var onDismiss: (() -> Void)?
    
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return version
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Timer Settings (Compact)
                    timerSettingsSection
                    
                    // App Settings
                    appSettingsSection
                    
                    // Account
                    accountSection
                    
                    // Open Dashboard
                    dashboardButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            checkNotificationAuthStatus()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 12) {
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text("Settings")
                .font(.system(size: 18, weight: .semibold))
            
            Spacer()
            
            Text("v\(appVersion)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Timer Settings Section
    
    private var timerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("Timer Duration")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 0) {
                CompactSettingRow(
                    title: "Focus Time",
                    value: $settings.focusDuration,
                    range: 1...60,
                    unit: "min"
                )
                
                Divider()
                    .padding(.leading, 16)
                
                CompactSettingRow(
                    title: "Short Break",
                    value: $settings.shortBreakDuration,
                    range: 1...30,
                    unit: "min"
                )
                
                Divider()
                    .padding(.leading, 16)
                
                CompactSettingRow(
                    title: "Long Break",
                    value: $settings.longBreakDuration,
                    range: 5...60,
                    unit: "min"
                )
                
                Divider()
                    .padding(.leading, 16)
                
                CompactSettingRow(
                    title: "Sessions until Long Break",
                    value: $settings.sessionsBeforeLongBreak,
                    range: 2...10,
                    unit: "sessions"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "app.badge")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("App Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 0) {
                // Notifications
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications")
                            .font(.system(size: 13, weight: .medium))
                        
                        if notificationAuthStatus == .denied {
                            Text("Permission required in System Settings")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.notificationsEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .disabled(notificationAuthStatus == .denied)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                
                if notificationAuthStatus == .denied {
                    Divider()
                        .padding(.leading, 46)
                    
                    Button(action: openSystemNotificationSettings) {
                        HStack {
                            Spacer()
                            Text("Open System Settings")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("Account")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 0) {
                if let user = authManager.currentUser {
                    // User Info
                    HStack(spacing: 12) {
                        UserProfileImage(size: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.isAnonymous ? "Guest" : (user.email ?? "User"))
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            
                            Text(user.isAnonymous ? "Anonymous Account" : "Account Connected")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    
                    Divider()
                        .padding(.leading, 62)
                }
                
                // Logout
                Button(action: {
                    authManager.signOut()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text("Log out")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Dashboard Button
    
    private var dashboardButton: some View {
        Button(action: {
            openWindow(id: "main")
            onDismiss?()
        }) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14))
                
                Text("See more in Dashboard")
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func checkNotificationAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationAuthStatus = settings.authorizationStatus
            }
        }
    }
    
    private func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Compact Setting Row

struct CompactSettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(value > range.lowerBound ? .secondary : .secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(minWidth: 28, alignment: .center)
                
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 24, alignment: .leading)
                
                Button(action: {
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(value < range.upperBound ? .secondary : .secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    MenuBarSettingsView()
        .environmentObject(PomodoroSettings())
        .environmentObject(AuthManager())
}

