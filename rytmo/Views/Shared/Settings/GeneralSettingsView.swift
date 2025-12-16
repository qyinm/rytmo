//
//  GeneralSettingsView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import FirebaseAuth
import UserNotifications

struct GeneralSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settings: PomodoroSettings

    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

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
                                        .lineLimit(1)
                                    
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
                                // .padding(.leading, 16)
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
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bell")
                                    .frame(width: 20)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)

                                Text("Notifications")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Toggle("", isOn: $settings.notificationsEnabled)
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                                    .disabled(notificationAuthStatus == .denied)
                            }

                            // 권한 거부 시 안내 메시지
                            if notificationAuthStatus == .denied {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.orange)

                                    Text("System notification permission is denied.")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)

                                    Button("Open Settings") {
                                        openSystemNotificationSettings()
                                    }
                                    .font(.system(size: 11))
                                    .buttonStyle(.link)
                                }
                                .padding(.leading, 28)
                            }
                        }
                        .padding(16)

                        Divider()
                            // .padding(.leading, 16)
                        
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

                            Text(appVersion)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(6)
                        }
                        .padding(16)
                        
                        Divider()
                            // .padding(.leading, 16)
                        
                        // Help / Support
                        Button {
                            openHelpAndSupport()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "questionmark.circle")
                                    .frame(width: 20)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Help & Support")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 4) {
                                        Text("Get rewarded for finding bugs")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)

                                        Image(systemName: "gift.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.red)
                                    }
                                }

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
        .onAppear {
            checkNotificationAuthStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // 앱이 활성화될 때마다 권한 상태 재확인
            checkNotificationAuthStatus()
        }
    }

    // MARK: - Helper Methods

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

    private func openMail(subject: String, body: String) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:support@dievas.ai?subject=\(encodedSubject)&body=\(encodedBody)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openEmailSupport() {
        let subject = "Rytmo Support Request"
        let body = """


        ---
        App Version: \(appVersion)
        macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """

        openMail(subject: subject, body: body)
    }

    private func reportBug() {
        let subject = "[Bug Report] Rytmo"
        let body = """
        Bug Description:
        [Please describe the bug you encountered]

        Steps to Reproduce:
        1.
        2.
        3.

        Expected Behavior:
        [What did you expect to happen?]

        Actual Behavior:
        [What actually happened?]

        ---
        App Version: \(appVersion)
        macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """

        openMail(subject: subject, body: body)
    }

    private func openHelpAndSupport() {
        let subject = "Rytmo Support Request"
        let body = """
        How can we help you?

        [ ] General Question / Inquiry
        [ ] Bug Report (Get rewarded!)
        [ ] Feature Request
        [ ] Other

        ---

        For General Inquiries:
        [Please describe your question or issue]



        For Bug Reports (Get rewarded for valid bugs!):

        Bug Description:
        [Describe the bug you encountered]

        Steps to Reproduce:
        1.
        2.
        3.

        Expected Behavior:
        [What did you expect to happen?]

        Actual Behavior:
        [What actually happened?]

        ---
        App Version: \(appVersion)
        macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """

        openMail(subject: subject, body: body)
    }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(AuthManager())
        .environmentObject(PomodoroSettings())
}
