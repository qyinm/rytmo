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
        .frame(minWidth: UIConstants.MainWindow.minWidth,
               idealWidth: UIConstants.MainWindow.idealWidth,
               maxWidth: .infinity,
               minHeight: UIConstants.MainWindow.minHeight,
               idealHeight: UIConstants.MainWindow.idealHeight,
               maxHeight: .infinity)
    }
}
