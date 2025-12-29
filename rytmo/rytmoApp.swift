//
//  rytmoApp.swift
//  rytmo
//
//  Created by hippoo on 12/3/25.
//

import SwiftUI
import SwiftData
import AmplitudeUnified
import FirebaseCore
import GoogleSignIn
import UserNotifications

@main
struct rytmoApp: App {

    // MARK: - State Objects

    @StateObject private var settings = PomodoroSettings()
    @StateObject private var timerManager: PomodoroTimerManager
    @StateObject private var musicPlayer = MusicPlayerManager()
    @StateObject private var authManager: AuthManager
    @StateObject private var updateManager = UpdateManager()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - SwiftData Container

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        // Firebase Crashlytics: Enable crash reporting on exceptions
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        // Initialize Firebase first (required before AuthManager initialization)
        FirebaseApp.configure()
        print("✅ Firebase initialization complete (App init)")

        let settings = PomodoroSettings()
        _settings = StateObject(wrappedValue: settings)
        _timerManager = StateObject(wrappedValue: PomodoroTimerManager(settings: settings))
        _authManager = StateObject(wrappedValue: AuthManager())

        // SwiftData container setup
        do {
            let schema = Schema([
                Playlist.self,
                MusicTrack.self,
                TodoItem.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        // 1) Default Window Group (Dashboard)
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(timerManager)
                .environmentObject(settings)
                .environmentObject(musicPlayer)
                .environmentObject(authManager)
                .tint(Color.primary.opacity(0.7))
                .onOpenURL { url in
                    // Handle Google Sign-In URL
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    musicPlayer.setModelContext(modelContainer.mainContext)
                }
        }
        // Window Size Settings
        .defaultSize(width: UIConstants.MainWindow.idealWidth,
                     height: UIConstants.MainWindow.idealHeight)
        .modelContainer(modelContainer)
        // Sparkle, Add Update Menu
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates") {
                    updateManager.checkForUpdates()
                }
            }
        }

        // 2) MenuBar Extra (Popover UI - Includes Settings)
        MenuBarExtra {
            MenuBarView()
                .environmentObject(timerManager)
                .environmentObject(settings)
                .environmentObject(musicPlayer)
                .environmentObject(authManager)
                .tint(Color.primary.opacity(0.7))
                .modelContainer(modelContainer)
                .onAppear {
                    musicPlayer.setModelContext(modelContainer.mainContext)
                }
        } label: {
            // Menubar Label (Icon + Timer)
            HStack(spacing: 4) {
                // Display different icons depending on timer status
                Group {
                    switch timerManager.session.state {
                    case .shortBreak, .longBreak:
                        Image(systemName: "cup.and.heat.waves")
                            .resizable()
                            .scaledToFit()
                    default:
                        Image("MenuBarIcon")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 16, height: 16)

                if !timerManager.menuBarTitle.isEmpty {
                    Text(timerManager.menuBarTitle)
                        .font(.system(.body, design: .monospaced))
                }
            }
            // Add ReopenHandler here to always receive events
            .background(ReopenHandler())
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Reopen Handler

struct ReopenHandler: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: .reopenMainWindow)) { _ in
                openWindow(id: "main")
            }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let reopenMainWindow = Notification.Name("reopenMainWindow")
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Firebase initialization moved to App's init, so removed

        // Amplitude initialization
        setupAmplitude()

        // Google Sign-In initialization
        setupGoogleSignIn()

        // UserNotifications Permission Request
        setupNotifications()

        // Bring window to front on app launch
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Always bring app to front
        NSApp.activate(ignoringOtherApps: true)

        // Check if we have any relevant windows to show (excluding background/hidden windows)
        // The background player window has isExcludedFromWindowsMenu = true
        // Also filter out windows that cannot become key (like Status Bar windows) to avoid warnings
        let validWindows = sender.windows.filter { 
            !$0.isExcludedFromWindowsMenu && 
            $0.isVisible && 
            $0.canBecomeKey 
        }
        
        if validWindows.isEmpty {
            // No valid windows found. We need to open a new one.
            // Since we can't directly open a SwiftUI WindowGroup from AppDelegate,
            // and the system might think the app is already open due to the background window,
            // we post a notification that the MenuBarExtra (which is always alive) will listen to.
            NotificationCenter.default.post(name: .reopenMainWindow, object: nil)
            return true
        } else {
            for window in validWindows {
                window.makeKeyAndOrderFront(self)
            }
            return false // We handled it
        }
    }

    private func setupGoogleSignIn() {
        // Google Sign-In settings handled in AuthManager
        // Only Client ID verification performed here
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("⚠️ Firebase Client ID not found.")
            return
        }

        print("✅ Google Sign-In ready (Client ID: \(String(clientID.prefix(20)))...)")
    }

    private func setupAmplitude() {
        let apiKey = Bundle.main.infoDictionary?["AMPLITUDE_API_KEY"] as? String ?? "YOUR_API_KEY_HERE"

        AmplitudeManager.shared.setup(apiKey: apiKey)
    }

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()

        // Check current permission status first
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // Permission not yet requested - Request permission
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("⚠️ Notification permission request failed: \(error.localizedDescription)")
                        return
                    }
                    print(granted ? "✅ Notification permission granted" : "⚠️ Notification permission denied")
                }
            default:
                break
            }
        }
    }
}
