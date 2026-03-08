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
@preconcurrency import UserNotifications

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

        // SwiftData container setup with automatic lightweight migration
        do {
            let schema = Schema([
                Playlist.self,
                MusicTrack.self,
                TodoItem.self,  // SwiftData will auto-migrate "content" -> "title" via @Attribute(originalName:)
                FocusSession.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            print("📦 Initializing SwiftData ModelContainer with automatic migration...")

            // SwiftData automatically handles lightweight migration
            // when @Attribute(originalName:) is used
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("✅ ModelContainer initialization complete")
        } catch {
            // Detailed error logging before crash
            print("❌ FATAL: ModelContainer initialization failed")
            print("❌ Error: \(error.localizedDescription)")
            print("❌ Details: \(error)")

            // This will crash the app, but with clear logs for debugging
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        // 1) Main Dashboard Window (singleton)
        Window("Rytmo", id: "main") {
            MainDashboardSceneView(
                timerManager: timerManager,
                settings: settings,
                musicPlayer: musicPlayer,
                authManager: authManager,
                updateManager: updateManager,
                modelContainer: modelContainer,
                appDelegate: appDelegate
            )
        }
        // Window Size Settings
        .defaultSize(width: UIConstants.MainWindow.idealWidth,
                     height: UIConstants.MainWindow.idealHeight)
        .modelContainer(modelContainer)
        // Sparkle, Add Update Menu
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Show Dashboard") {
                    appDelegate.showMainWindow()
                }
                .keyboardShortcut("n")
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates") {
                    updateManager.checkForUpdates()
                }
            }
        }

        /*
        // 2) MenuBar Extra (Popover UI - Includes Settings)
        // Disabled in favor of Notch UI (Migration to Dynamic Island experience)
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
                    timerManager.setModelContext(modelContainer.mainContext)
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
            // Dock reopen is handled via MainWindowOpenerBridge registration on the main window
        }
        .menuBarExtraStyle(.window)
        */
    }
}

// MARK: - Main Dashboard Scene

struct MainDashboardSceneView: View {
    let timerManager: PomodoroTimerManager
    let settings: PomodoroSettings
    let musicPlayer: MusicPlayerManager
    let authManager: AuthManager
    let updateManager: UpdateManager
    let modelContainer: ModelContainer
    let appDelegate: AppDelegate

    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        ContentView()
            .environmentObject(timerManager)
            .environmentObject(settings)
            .environmentObject(musicPlayer)
            .environmentObject(authManager)
            .tint(Color.primary.opacity(0.7))
            .background(
                MainWindowAccessor { window in
                    appDelegate.registerMainWindow(window)
                }
            )
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .onAppear {
                appDelegate.registerMainWindowOpener {
                    openWindow(id: "main")
                }

                musicPlayer.setModelContext(modelContainer.mainContext)
                musicPlayer.startBackgroundPlayerIfNeeded()
                timerManager.setModelContext(modelContainer.mainContext)
                updateManager.startUpdaterIfNeeded()
                
                appDelegate.setupNotchWindow(
                    timerManager: timerManager,
                    settings: settings,
                    musicPlayer: musicPlayer,
                    authManager: authManager,
                    modelContainer: modelContainer
                )
            }
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> MainWindowTrackingView {
        let view = MainWindowTrackingView()
        view.onResolve = onResolve
        return view
    }

    func updateNSView(_ nsView: MainWindowTrackingView, context: Context) {
        nsView.onResolve = onResolve
        DispatchQueue.main.async {
            if let window = nsView.window {
                onResolve(window)
            }
        }
    }
}

private final class MainWindowTrackingView: NSView {
    var onResolve: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if let window {
            onResolve?(window)
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("rytmo.mainWindow")

    private var notchViewModel: NotchViewModel?
    private var timerManagerRef: PomodoroTimerManager?
    private var settingsRef: PomodoroSettings?
    private var musicPlayerRef: MusicPlayerManager?
    private var authManagerRef: AuthManager?
    private var modelContainerRef: ModelContainer?
    private var mainWindowController: NSWindowController?
    private var openMainWindowAction: (() -> Void)?

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
    
    func setupNotchWindow(
        timerManager: PomodoroTimerManager,
        settings: PomodoroSettings,
        musicPlayer: MusicPlayerManager,
        authManager: AuthManager,
        modelContainer: ModelContainer
    ) {
        guard notchViewModel == nil else { return }
        
        self.timerManagerRef = timerManager
        self.settingsRef = settings
        self.musicPlayerRef = musicPlayer
        self.authManagerRef = authManager
        self.modelContainerRef = modelContainer
        
        let vm = NotchViewModel()
        self.notchViewModel = vm
        
        let notchContent = NotchContentView(timerManager: timerManager)
            .environmentObject(vm)
            .environmentObject(timerManager)
            .environmentObject(settings)
            .environmentObject(musicPlayer)
            .environmentObject(authManager)
            .modelContainer(modelContainer)
        
        NotchWindowManager.shared.setup(with: notchContent)
    }
    
    func registerMainWindowOpener(_ action: @escaping () -> Void) {
        openMainWindowAction = action
    }
    
    func registerMainWindow(_ window: NSWindow) {
        window.identifier = Self.mainWindowIdentifier
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        if mainWindowController?.window !== window {
            mainWindowController = NSWindowController(window: window)
        }
    }
    
    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        if let mainWindow = mainWindowController?.window {
            mainWindowController?.showWindow(self)
            mainWindow.makeKeyAndOrderFront(self)
            return
        }
        
        openMainWindowAction?()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Always bring app to front
        NSApp.activate(ignoringOtherApps: true)
        
        let visibleUserWindows = sender.windows.filter {
            !$0.isExcludedFromWindowsMenu &&
            !($0 is NSPanel) &&
            $0.isVisible
        }
        
        if visibleUserWindows.isEmpty {
            showMainWindow()
            return true
        }
        
        for window in visibleUserWindows {
            window.makeKeyAndOrderFront(self)
        }
        return false
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard sender.identifier == Self.mainWindowIdentifier else { return true }
        sender.orderOut(nil)
        return false
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
