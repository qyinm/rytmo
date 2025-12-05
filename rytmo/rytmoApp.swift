//
//  rytmoApp.swift
//  rytmo
//
//  Created by hippoo on 12/3/25.
//

import SwiftUI
import SwiftData

@main
struct rytmoApp: App {

    // MARK: - State Objects

    @StateObject private var settings = PomodoroSettings()
    @StateObject private var timerManager: PomodoroTimerManager
    @StateObject private var musicPlayer = MusicPlayerManager()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - SwiftData Container

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
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
        }
        // 윈도우 크기 설정
        .defaultSize(width: 800, height: 600)
        .modelContainer(modelContainer)

        // 2) 메뉴바 Extra (팝오버 UI - 설정 포함)
        MenuBarExtra {
            MenuBarView()
                .environmentObject(timerManager)
                .environmentObject(settings)
                .environmentObject(musicPlayer)
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
        // Dock 아이콘 숨기기 (메뉴바 전용 앱)
        NSApp.setActivationPolicy(.accessory)
    }
}
