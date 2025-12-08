//
//  ContentView.swift
//  rytmo
//
//  Created by hippoo on 12/3/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var authManager: AuthManager

    // MARK: - Body

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                DashboardView()
            } else {
                LoginView()
            }
        }
        .frame(minWidth: 980, minHeight: 600)
    }
}
