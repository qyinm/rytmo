//
//  DashboardTodoView.swift
//  rytmo
//
//  Created by gemini-code-assist on 12/24/25.
//

import SwiftUI
import SwiftData

struct DashboardTodoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Tasks")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("집중 모드에서 완수할 목표들을 관리하세요.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Content Section
                TodoListView(showHeader: true, compact: false)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .frame(maxWidth: 800) // Limit width for better readability on large screens
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    DashboardTodoView()
        .frame(width: 800, height: 600)
}

