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

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("타이머 설정")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // 설정 항목
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 집중 시간
                    SettingRow(
                        icon: "🍅",
                        title: "집중 시간",
                        value: $settings.focusDuration,
                        range: 1...60,
                        unit: "분"
                    )

                    Divider()

                    // 짧은 휴식 시간
                    SettingRow(
                        icon: "☕️",
                        title: "짧은 휴식",
                        value: $settings.shortBreakDuration,
                        range: 1...30,
                        unit: "분"
                    )

                    Divider()

                    // 긴 휴식 시간
                    SettingRow(
                        icon: "🌟",
                        title: "긴 휴식",
                        value: $settings.longBreakDuration,
                        range: 5...60,
                        unit: "분"
                    )

                    Divider()

                    // 긴 휴식 전 세션 수
                    SettingRow(
                        icon: "🔢",
                        title: "긴 휴식 전 세션 수",
                        value: $settings.sessionsBeforeLongBreak,
                        range: 2...10,
                        unit: "세트"
                    )
                }
                .padding()
            }

            Divider()

            // 하단 버튼
            Button(action: {
                settings.resetToDefaults()
            }) {
                Text("기본값 복원")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 400, height: 500)
    }
}

// MARK: - Setting Row

/// 설정 항목 행
struct SettingRow: View {

    let icon: String
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(icon)
                    .font(.title3)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(value) \(unit)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(PomodoroSettings())
}
