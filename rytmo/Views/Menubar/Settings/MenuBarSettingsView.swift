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
/// 메뉴바 전용 컴팩트한 설정 화면
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
        ScrollView {
            VStack(spacing: 0) {
                // 헤더
                header
                
                Divider()
                    .padding(.bottom, 16)
                
                VStack(spacing: 16) {
                    // 타이머 설정 (컴팩트)
                    timerSettingsSection
                    
                    // 앱 설정
                    appSettingsSection
                    
                    // 계정
                    accountSection
                    
                    // 대시보드 열기
                    dashboardButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
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
            
            Text("설정")
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
                Text("타이머 시간")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 0) {
                CompactSettingRow(
                    title: "집중 시간",
                    value: $settings.focusDuration,
                    range: 1...60,
                    unit: "분"
                )
                
                Divider()
                    .padding(.leading, 16)
                
                CompactSettingRow(
                    title: "짧은 휴식",
                    value: $settings.shortBreakDuration,
                    range: 1...30,
                    unit: "분"
                )
                
                Divider()
                    .padding(.leading, 16)
                
                CompactSettingRow(
                    title: "긴 휴식",
                    value: $settings.longBreakDuration,
                    range: 5...60,
                    unit: "분"
                )
                
                Divider()
                    .padding(.leading, 16)
                
                CompactSettingRow(
                    title: "긴 휴식까지",
                    value: $settings.sessionsBeforeLongBreak,
                    range: 2...10,
                    unit: "세션"
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
                Text("앱 설정")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 0) {
                // 알림
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("알림")
                            .font(.system(size: 13, weight: .medium))
                        
                        if notificationAuthStatus == .denied {
                            Text("시스템 설정에서 권한 허용 필요")
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
                            Text("시스템 설정 열기")
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
                Text("계정")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 0) {
                if let user = authManager.currentUser {
                    // 사용자 정보
                    HStack(spacing: 12) {
                        UserProfileImage(size: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.isAnonymous ? "게스트" : (user.email ?? "사용자"))
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            
                            Text(user.isAnonymous ? "익명 계정" : "계정 연결됨")
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
                
                // 로그아웃
                Button(action: {
                    authManager.signOut()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text("로그아웃")
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
                
                Text("대시보드에서 더 보기")
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

