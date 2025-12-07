//
//  DashboardView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import FirebaseAuth

//
//  DashboardView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

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
                PlaylistView()
            case .playlist(let playlist):
                // 개별 플레이리스트 뷰가 따로 없다면 PlaylistView에 선택된 상태로 전달하거나
                // HomeView에서 해당 플레이리스트를 재생하도록 할 수 있습니다.
                // 여기서는 HomeView를 보여주되, 선택된 플레이리스트를 MusicPlayerManager에 설정하는 로직을 추가하면 좋습니다.
                // 편의상 PlaylistView를 재활용하되, 해당 플레이리스트만 강조하는 형태로 가거나, 
                // HomeView로 이동해 플레이리스트를 보여주는 것이 자연스러울 수 있습니다.
                // User Request: "플레이리스트 리스트들이 보이게 해줘" -> It implies navigation.
                
                // For now, let's navigate to HomeView and select the playlist automatically via onAppear is tricky in split view.
                // Better: Show tracks of that playlist.
                // Since user didn't specify detailed "Single Playlist View", I'll show tracks here simply or just PlaylistView.
                // Let's create a Simple Track List for specifically selected playlist, or re-use HomeView context.
                
                // Let's redirect to HomeView and set selected playlist.
                HomeView()
                    .onAppear {
                        musicPlayer.selectedPlaylist = playlist
                    }
                    
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
