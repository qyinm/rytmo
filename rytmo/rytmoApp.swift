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
        // Firebase Crashlytics: 예외 발생 시 크래시 리포팅 활성화
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        // Firebase 초기화를 가장 먼저 수행 (AuthManager 초기화 전에 필요)
        FirebaseApp.configure()
        print("✅ Firebase 초기화 완료 (App init)")

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
        // 1) 기본 윈도우 그룹 (대시보드)
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(timerManager)
                .environmentObject(settings)
                .environmentObject(musicPlayer)
                .environmentObject(authManager)
                .tint(Color.primary.opacity(0.7))
                .onOpenURL { url in
                    // Google Sign-In URL 처리
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    musicPlayer.setModelContext(modelContainer.mainContext)
                }
        }
        // 윈도우 크기 설정
        .defaultSize(width: UIConstants.MainWindow.idealWidth,
                     height: UIConstants.MainWindow.idealHeight)
        .modelContainer(modelContainer)
        // Sparkle, 업데이트 메뉴 추가
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates") {
                    updateManager.checkForUpdates()
                }
            }
        }

        // 2) 메뉴바 Extra (팝오버 UI - 설정 포함)
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
            // 메뉴바 라벨 (아이콘 + 타이머)
            HStack(spacing: 4) {
                // 타이머 상태에 따라 다른 아이콘 표시
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
            // ReopenHandler를 여기에 추가하여 항상 이벤트를 수신할 수 있게 함
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
        // Firebase 초기화는 App의 init으로 이동했으므로 제거됨

        // Amplitude 초기화
        setupAmplitude()

        // Google Sign-In 초기화
        setupGoogleSignIn()

        // UserNotifications 권한 요청
        setupNotifications()

        // 앱 실행 시 윈도우를 맨 앞으로 가져오기
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
        // Google Sign-In 설정은 AuthManager에서 처리됨
        // 여기서는 Client ID 검증만 수행
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("⚠️ Firebase Client ID를 찾을 수 없습니다.")
            return
        }

        print("✅ Google Sign-In 준비 완료 (Client ID: \(String(clientID.prefix(20)))...)")
    }

    private func setupAmplitude() {
        let apiKey = Bundle.main.infoDictionary?["AMPLITUDE_API_KEY"] as? String ?? "YOUR_API_KEY_HERE"

        AmplitudeManager.shared.setup(apiKey: apiKey)
    }

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()

        // 먼저 현재 권한 상태를 확인
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // 아직 권한을 요청하지 않음 - 권한 요청
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("⚠️ 알림 권한 요청 실패: \(error.localizedDescription)")
                        return
                    }
                    print(granted ? "✅ 알림 권한 승인됨" : "⚠️ 알림 권한 거부됨")
                }
            default:
                break
            }
        }
    }
}
