//
//  SettingRow.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI

/// 설정 항목 행 (슬라이더 포함)
struct SettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
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

#Preview {
    SettingRow(title: "Test", value: .constant(25), range: 1...60, unit: "min")
        .padding()
}
