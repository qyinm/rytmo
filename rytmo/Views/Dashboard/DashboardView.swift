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

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Query(sort: \Playlist.orderIndex) private var playlists: [Playlist]
    
    @State private var selection: DashboardSelection? = .home
    @State private var isPlaylistExpanded: Bool = true
    
    enum DashboardSelection: Hashable {
        case home
        case allPlaylists
        case playlist(Playlist)
        case settings
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
                            Text("Settings") // Hide title visually if icon only requested previously, but sidebar usually needs text.
                        } icon: {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            
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
