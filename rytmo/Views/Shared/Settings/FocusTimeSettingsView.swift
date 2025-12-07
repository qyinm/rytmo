//
//  FocusTimeSettingsView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI

struct FocusTimeSettingsView: View {
    @EnvironmentObject var settings: PomodoroSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // Durations Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Timer Durations")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        // Focus Duration
                        VStack(spacing: 16) {
                            SettingRow(
                                title: "Focus Duration",
                                value: $settings.focusDuration,
                                range: 1...60,
                                unit: "min"
                            )
                            
                            Divider()
                            
                            SettingRow(
                                title: "Short Break",
                                value: $settings.shortBreakDuration,
                                range: 1...30,
                                unit: "min"
                            )
                            
                            Divider()
                            
                            SettingRow(
                                title: "Long Break",
                                value: $settings.longBreakDuration,
                                range: 5...60,
                                unit: "min"
                            )
                        }
                        .padding(20)
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Session Management Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Management")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        SettingRow(
                            title: "Sessions before Long Break",
                            value: $settings.sessionsBeforeLongBreak,
                            range: 2...10,
                            unit: "sessions"
                        )
                        .padding(20)
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                
                // Reset Button
                Button {
                    settings.resetToDefaults()
                } label: {
                    Text("Reset to Defaults")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    FocusTimeSettingsView()
        .environmentObject(PomodoroSettings())
}
