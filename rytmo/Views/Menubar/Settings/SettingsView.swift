//
//  SettingsView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI

// MARK: - Settings View

/// 포모도로 타이머 설정 화면
struct SettingsView: View {

    @EnvironmentObject var settings: PomodoroSettings
    var onDismiss: (() -> Void)? = nil

    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }

                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            TabView(selection: $selectedTab) {
                GeneralSettingsView()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(0)
                
                FocusTimeSettingsView()
                    .tabItem {
                        Label("Focus time", systemImage: "timer")
                    }
                    .tag(1)
            }
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(PomodoroSettings())
}
