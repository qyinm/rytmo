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

@main
struct rytmoApp: App {

    // MARK: - State Objects

    @StateObject private var settings = PomodoroSettings()
    @StateObject private var timerManager: PomodoroTimerManager
    @StateObject private var musicPlayer = MusicPlayerManager()
    @StateObject private var authManager = AuthManager()
    @StateObject private var updateManager = UpdateManager()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - SwiftData Container

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        // Firebase 초기화를 가장 먼저 수행 (AuthManager 초기화 전에 필요)
        FirebaseApp.configure()
        print("✅ Firebase 초기화 완료 (App init)")

        let settings = PomodoroSettings()
        _settings = StateObject(wrappedValue: settings)
        _timerManager = StateObject(wrappedValue: PomodoroTimerManager(settings: settings))

        // SwiftData container setup
        do {
            let schema = Schema([Playlist.self, MusicTrack.self])
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
                .onOpenURL { url in
                    // Google Sign-In URL 처리
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        // 윈도우 크기 설정
        .defaultSize(width: 1390, height: 800)
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
                .modelContainer(modelContainer)
                .onAppear {
                    musicPlayer.setModelContext(modelContainer.mainContext)
                }
        } label: {
            // 메뉴바 라벨 (아이콘 + 타이머)
            HStack(spacing: 4) {
                Image("MenuBarIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)

                if !timerManager.menuBarTitle.isEmpty {
                    Text(timerManager.menuBarTitle)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Firebase 초기화는 App의 init으로 이동했으므로 제거됨

        // Amplitude 초기화
        setupAmplitude()

        // Google Sign-In 초기화
        setupGoogleSignIn()
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
}
