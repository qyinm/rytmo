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
    
    var body: some View {
        Form {
            Section("Account") {
                if let user = authManager.currentUser {
                    LabeledContent("Email", value: user.email ?? "Anonymous")
                    LabeledContent("User ID", value: String(user.uid.prefix(8)).uppercased())
                }
                
                Button(role: .destructive) {
                    authManager.signOut()
                } label: {
                    Text("Sign Out")
                }
            }
            
            Section("App") {
                LabeledContent("Version", value: "1.0.0")
                Toggle("Notifications", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    DashboardSettingsView()
        .environmentObject(AuthManager())
}
