//
//  DashboardView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selection: SidebarItem? = .home
    
    enum SidebarItem: String, CaseIterable, Identifiable {
        case home = "Home"
        case playlist = "Playlist"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .playlist: return "music.note.list"
            case .settings: return "gearshape.fill"
            }
        }
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .playlist: return "Playlist"
            case .settings: return "" // Icon only
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                // Profile Section
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(authManager.currentUser?.uid.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        if let user = authManager.currentUser {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.isAnonymous ? "Guest" : (user.email ?? "User"))
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                Text("Premium")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Guest")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
                
                // Navigation Links
                Section {
                    ForEach(SidebarItem.allCases) { item in
                        NavigationLink(value: item) {
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16))
                                    .frame(width: 20, alignment: .center)
                                    .foregroundStyle(selection == item ? .white : .primary)
                                
                                if !item.title.isEmpty {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(selection == item ? .white : .primary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    Text("Menu")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 10)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            
        } detail: {
            switch selection {
            case .home, .none:
                HomeView()
            case .playlist:
                PlaylistView()
            case .settings:
                DashboardSettingsView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .frame(width: 1000, height: 700)
}
