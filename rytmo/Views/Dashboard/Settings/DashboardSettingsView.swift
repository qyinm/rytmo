//
//  DashboardSettingsView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import FirebaseAuth

struct DashboardSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settings: PomodoroSettings
    
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            // Custom Tab Bar
            HStack(spacing: 8) {
                DashboardTabButton(title: "General", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                DashboardTabButton(title: "Focus time", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

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
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct DashboardTabButton: View {
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




#Preview {
    DashboardSettingsView()
        .environmentObject(AuthManager())
        .environmentObject(PomodoroSettings())
}
