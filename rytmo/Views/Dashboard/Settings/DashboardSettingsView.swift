//
//  DashboardSettingsView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import FirebaseAuth

struct DashboardSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settings: PomodoroSettings
    
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            FocusTimeSettingsTab()
                .tabItem {
                    Label("Focus time", systemImage: "timer")
                }
                .tag(1)
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - General Tab

// MARK: - General Tab

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // Account Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        if let user = authManager.currentUser {
                            // User Info Row
                            HStack(spacing: 16) {
                                UserProfileImage(size: 48)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.email ?? "Anonymous")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 6) {
                                        Text("ID: \(String(user.uid.prefix(8)).uppercased())")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.tertiary)
                                            .monospaced()
                                        
                                        Button {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(user.uid, forType: .string)
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Copy User ID")
                                    }
                                }
                                Spacer()
                            }
                            .padding(16)
                            
                            Divider()
                                .padding(.leading, 16)
                        }
                        
                        // Sign Out Row
                        Button {
                            authManager.signOut()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14))
                                Text("Log out")
                                    .font(.system(size: 14))
                                Spacer()
                            }
                            .foregroundStyle(.primary.opacity(0.8))
                            .padding(16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovered in
                            if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // App Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Application")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        // Notifications
                        HStack {
                            Image(systemName: "bell")
                                .frame(width: 20)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                            
                            Text("Notifications")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                        .padding(16)
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        // Version
                        HStack {
                            Image(systemName: "info.circle")
                                .frame(width: 20)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                            
                            Text("Version")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("1.0.0")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(6)
                        }
                        .padding(16)
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        // Help / Support
                        Button {
                            // Action
                        } label: {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .frame(width: 20)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                
                                Text("Help & Support")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Focus Time Tab

struct FocusTimeSettingsTab: View {
    @EnvironmentObject var settings: PomodoroSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox(label: Text("Timer Durations").font(.headline)) {
                    VStack(spacing: 16) {
                        SettingRow(
                            title: "Focus Duration",
                            value: $settings.focusDuration,
                            range: 1...60,
                            unit: "min"
                        )
                        
                        SettingRow(
                            title: "Short Break",
                            value: $settings.shortBreakDuration,
                            range: 1...30,
                            unit: "min"
                        )
                        
                        SettingRow(
                            title: "Long Break",
                            value: $settings.longBreakDuration,
                            range: 5...60,
                            unit: "min"
                        )
                    }
                    .padding(8)
                }
                
                GroupBox(label: Text("Session Management").font(.headline)) {
                    VStack(spacing: 16) {
                        SettingRow(
                            title: "Sessions before Long Break",
                            value: $settings.sessionsBeforeLongBreak,
                            range: 2...10,
                            unit: "sessions"
                        )
                    }
                    .padding(8)
                }
                
                GroupBox {
                    Button(role: .cancel) {
                        settings.resetToDefaults()
                    } label: {
                        Text("Reset to Defaults")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .padding(4)
                }
            }
            .padding()
        }
    }
}

// MARK: - Components



#Preview {
    DashboardSettingsView()
        .environmentObject(AuthManager())
        .environmentObject(PomodoroSettings())
}
