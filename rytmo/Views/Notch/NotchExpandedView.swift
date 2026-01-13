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
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private var mainContent: some View {
        VStack(spacing: 12) {
            headerView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    MenuBarTimerView()
                    MenuBarTodoView()
                    MenuBarMusicView()
                }
                .padding(.bottom, 10)
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
        VStack(spacing: 12) {
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
            }
            
            MenuBarSettingsView(onDismiss: {
                showingSettings = false
            })
        }
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
