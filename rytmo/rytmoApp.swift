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
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        FirebaseApp.configure()
        print("✅ Firebase initialization complete (App init)")

        let settings = PomodoroSettings()
        _settings = StateObject(wrappedValue: settings)
        _timerManager = StateObject(wrappedValue: PomodoroTimerManager(settings: settings))
        _authManager = StateObject(wrappedValue: AuthManager())

        do {
            let schema = Schema([
                Playlist.self,
                MusicTrack.self,
                TodoItem.self,
                FocusSession.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            print("📦 Initializing SwiftData ModelContainer with automatic migration...")

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("✅ ModelContainer initialization complete")
        } catch {
            print("❌ FATAL: ModelContainer initialization failed")
            print("❌ Error: \(error.localizedDescription)")
            print("❌ Details: \(error)")

            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup("Rytmo", id: "main") {
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
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.presented)
        .defaultSize(width: UIConstants.MainWindow.idealWidth,
                     height: UIConstants.MainWindow.idealHeight)
        .modelContainer(modelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    appDelegate.showMainWindow()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .createNewTask, object: nil)
                    }
                }
                .keyboardShortcut("n")

                Button("New Event") {
                    appDelegate.showMainWindow()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .createNewEvent, object: nil)
                    }
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandMenu("Timer") {
                Button(timerManager.session.isRunning ? "Pause Timer" : "Start Timer") {
                    if timerManager.session.isRunning {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Skip Session") {
                    timerManager.skip()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Reset Timer") {
                    timerManager.reset()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }

            CommandMenu("Playback") {
                Button("Toggle Play/Pause") {
                    musicPlayer.togglePlayPause()
                }
                .keyboardShortcut("k")

                Button("Next Track") {
                    musicPlayer.playNextTrack()
                }
                .keyboardShortcut("]", modifiers: .command)

                Button("Previous Track") {
                    musicPlayer.playPreviousTrack()
                }
                .keyboardShortcut("[", modifiers: .command)
            }

            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }

            CommandGroup(after: .appInfo) {
                Button("Check for Updates") {
                    updateManager.checkForUpdates()
                }
            }
        }

        Settings {
            DashboardSettingsView()
                .environmentObject(authManager)
                .environmentObject(settings)
                .modelContainer(modelContainer)
        }
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
    @Environment(\.openSettings) private var openSettings

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
            .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
                openSettings()
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
        setupAmplitude()
        setupGoogleSignIn()
        setupNotifications()

        NotificationCenter.default.addObserver(
            forName: .showDashboard,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showMainWindow()
            }
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
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

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
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
