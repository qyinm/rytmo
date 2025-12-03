//
//  rytmoApp.swift
//  rytmo
//
//  Created by hippoo on 12/3/25.
//

import SwiftUI

@main
struct rytmoApp: App {
    var body: some Scene {
        // 1) 기본 윈도우 그룹에 식별자 부여
        WindowGroup(id: "main") {
            ContentView()
        }
        
        // 2) 메뉴바 아이콘
        MenuBarExtra("Status", image: "MenuBarIcon") {
            Button("열기") {
                // Read the environment from within a View context
                let openWindow = Environment(\.openWindow).wrappedValue
                openWindow(id: "main")
            }
            Divider()
            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
