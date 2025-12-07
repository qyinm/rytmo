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
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                List(selection: $selection) {
                    // Profile Section
                    Section {
                        HStack(spacing: 12) {
                            UserProfileImage(size: 32)
                            
                            if let user = authManager.currentUser {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.isAnonymous ? "Guest" : (user.email ?? "User"))
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                }
                            } else {
                                Text("Guest")
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        .padding(.vertical, 8)
                    }
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
                        

                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Button {
                            selection = .settings
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: selection == .settings ? "gearshape.fill" : "gearshape")
                                    .font(.system(size: 14))
                                    .foregroundStyle(selection == .settings ? .white : .primary)
                                
                                Text("Settings")
                                    .font(.system(size: 14))
                                    .foregroundStyle(selection == .settings ? .white : .primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == .settings ? Color.accentColor : Color.clear)
                        )
                    .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                    }
                }
                
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




#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .frame(width: 1000, height: 700)
}
