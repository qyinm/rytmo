import SwiftUI

struct NotchExpandedView: View {
    @ObservedObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @EnvironmentObject var vm: NotchViewModel
    
    @State private var showingSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.isLoggedIn {
                if showingSettings {
                    settingsContent
                } else {
                    mainContent
                }
            } else {
                loginContent
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private var mainContent: some View {
        VStack(spacing: 8) {
            headerView
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                MenuBarTimerView()
                MenuBarTodoView()
                MenuBarMusicView()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Rytmo")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        showingSettings = true
                    }
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    authManager.signOut()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var settingsContent: some View {
        VStack(spacing: 0) {
            settingsHeader
            
            Divider()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    settingsTimerSection
                    settingsAppSection
                    settingsAccountSection
                    settingsDashboardButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }
    
    private var settingsHeader: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showingSettings = false
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 16, weight: .bold))
        }
        .padding(.bottom, 8)
    }
    
    private var settingsTimerSection: some View {
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
                    value: .constant(25),
                    range: 1...60,
                    unit: "min"
                )
                Divider().padding(.leading, 16)
                CompactSettingRow(
                    title: "Short Break",
                    value: .constant(5),
                    range: 1...30,
                    unit: "min"
                )
                Divider().padding(.leading, 16)
                CompactSettingRow(
                    title: "Long Break",
                    value: .constant(15),
                    range: 5...60,
                    unit: "min"
                )
                Divider().padding(.leading, 16)
                CompactSettingRow(
                    title: "Sessions until Long Break",
                    value: .constant(4),
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
    
    private var settingsAppSection: some View {
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
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text("Notifications")
                        .font(.system(size: 13, weight: .medium))
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
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
    
    private var settingsAccountSection: some View {
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
    
    private var settingsDashboardButton: some View {
        Button(action: {
            // Open dashboard
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
    
    private var loginContent: some View {
        VStack(spacing: 24) {
            Image("RytmoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .cornerRadius(12)
            
            VStack(spacing: 8) {
                Text("Welcome to Rytmo")
                    .font(.system(size: 20, weight: .bold))
                Text("Login to sync your focus sessions and tasks")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    Task { await authManager.signInWithGoogle() }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView().controlSize(.small).scaleEffect(0.8)
                        } else {
                            Image(systemName: "g.circle.fill")
                        }
                        Text("Continue with Google")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)
                
                Button(action: {
                    Task { await authManager.signInAnonymously() }
                }) {
                    Text("Start Anonymously")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)
            }
        }
        .padding(.vertical, 40)
    }
}
