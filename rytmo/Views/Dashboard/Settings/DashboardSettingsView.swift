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
        .padding(20)
        .frame(minWidth: 500, minHeight: 400)
    }
}





#Preview {
    DashboardSettingsView()
        .environmentObject(AuthManager())
        .environmentObject(PomodoroSettings())
}
