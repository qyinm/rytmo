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
            // Header
            HStack {
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(.secondary)
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

            // Custom Tab Bar
            HStack(spacing: 8) {
                SettingsTabButton(title: "General", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                SettingsTabButton(title: "Focus time", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Content
            Group {
                if selectedTab == 0 {
                    GeneralSettingsView()
                } else {
                    FocusTimeSettingsView()
                }
            }
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Components

struct SettingsTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.primary.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(PomodoroSettings())
}
