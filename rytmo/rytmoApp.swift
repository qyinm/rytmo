//
//  rytmoApp.swift
//  rytmo
//
//  Created by hippoo on 12/3/25.
//

import SwiftUI

@main
struct rytmoApp: App {

    // MARK: - State Objects

    @StateObject private var timerManager = PomodoroTimerManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Body

    var body: some Scene {
        // 1) 기본 윈도우 그룹 (대시보드)
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(timerManager)
        }
        // 윈도우 크기 설정
        .defaultSize(width: 800, height: 600)

        // 2) 메뉴바 Extra (팝오버 UI)
        MenuBarExtra {
            MenuBarView()
                .environmentObject(timerManager)
        } label: {
            // 메뉴바 라벨 (모노스페이스 폰트로 깜빡임 방지)
            Text(timerManager.menuBarTitle)
                .font(.system(.body, design: .monospaced))
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
