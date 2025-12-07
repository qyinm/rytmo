//
//  DashboardView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth
import YouTubePlayerKit

enum DashboardSelection: Hashable {
    case home
    case allPlaylists
    case playlist(Playlist)
    case settings
}

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Query(sort: \Playlist.orderIndex) private var playlists: [Playlist]
    
    @State private var selection: DashboardSelection? = .home
    @State private var isPlaylistExpanded: Bool = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Side Rail (Visible when Sidebar is hidden)
            if columnVisibility == .detailOnly {
                SideRailView(selection: $selection)
                    .transition(.move(edge: .leading))
            }
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
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
                    
                    // Menu Section
                    Section("Menu") {
                        NavigationLink(value: DashboardSelection.home) {
                            Label("Home", systemImage: "house.fill")
                        }
                        
                        DisclosureGroup(isExpanded: $isPlaylistExpanded) {
                            ForEach(playlists.prefix(5)) { playlist in
                                NavigationLink(value: DashboardSelection.playlist(playlist)) {
                                    Label(playlist.name, systemImage: "music.note.list")
                                }
                            }
                            
                            if playlists.count > 5 {
                                NavigationLink(value: DashboardSelection.allPlaylists) {
                                    Label("More...", systemImage: "ellipsis.circle")
                                }
                            }
                        } label: {
                            NavigationLink(value: DashboardSelection.allPlaylists) {
                                Label("Playlists", systemImage: "music.note")
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        NavigationLink(value: DashboardSelection.settings) {
                            Label {
                                Text("Settings")
                            } icon: {
                                Image(systemName: "gearshape.fill")
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
                // Add a toggle sidebar button if needed, but standard toolbar usually handles it.
                
            } detail: {
                switch selection {
                case .home, .none:
                    HomeView()
                case .allPlaylists:
                    PlaylistView(onSelect: { playlist in
                        selection = .playlist(playlist)
                    })
                case .playlist(let playlist):
                    PlaylistDetailView(playlist: playlist, onBack: {
                        selection = .allPlaylists
                    })
                    .id(playlist.id) // Force update when switching playlists via sidebar
                        
                case .settings:
                    DashboardSettingsView()
                        .environmentObject(authManager)
                }
            }
        }
        // Persistent Player Layer
        .overlay(
            YouTubePlayerView(musicPlayer.youTubePlayer)
                .frame(width: 1, height: 1)
                .opacity(0)
        )
    }
}

// MARK: - Side Rail View
struct SideRailView: View {
    @Binding var selection: DashboardSelection?
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Icon
            Button {
                // Navigate to settings on profile click? or just visual
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    Text(String(authManager.currentUser?.uid.prefix(1) ?? "U").uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 10)
                .opacity(0.5)
            
            // Navigation Icons
            Group {
                railButton(icon: "house", selectedIcon: "house.fill", selectionValue: .home)
                
                railButton(icon: "music.note", selectedIcon: "music.note", selectionValue: .allPlaylists, isSelected: isPlaylistSelected)
            }
            
            Spacer()
            
            railButton(icon: "gearshape", selectedIcon: "gearshape.fill", selectionValue: .settings)
                .padding(.bottom, 16)
        }
        .frame(width: 50)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.primary.opacity(0.05)),
            alignment: .trailing
        )
        .zIndex(1)
    }
    
    private var isPlaylistSelected: Bool {
        if case .allPlaylists = selection { return true }
        if case .playlist = selection { return true }
        return false
    }
    
    private func railButton(icon: String, selectedIcon: String, selectionValue: DashboardSelection, isSelected: Bool? = nil) -> some View {
        let selected = isSelected ?? (selection == selectionValue)
        
        return Button {
            selection = selectionValue
        } label: {
            ZStack {
                if selected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 30, height: 30)
                }
                
                Image(systemName: selected ? selectedIcon : icon)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .opacity(selected ? 1.0 : 0.6)
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(String(describing: selectionValue).capitalized)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .frame(width: 1000, height: 700)
}
