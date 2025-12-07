//
//  PlaylistView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData

struct PlaylistView: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Query(sort: \Playlist.orderIndex) private var playlists: [Playlist]
    @State private var hoveredPlaylistId: UUID?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Image(systemName: "music.note.list")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Text("Playlists")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                
                // List Header
                HStack {
                    Text("NAME")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 200, alignment: .leading)
                    
                    Text("TRACKS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                    
                    Spacer() // Spacer for flexible width
                    
                    Text("SOURCE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal, 24)
                
                if playlists.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No playlists yet")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Text("Create a playlist to get started")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(playlists) { playlist in
                            PlaylistRow(playlist: playlist, isHovered: hoveredPlaylistId == playlist.id)
                                .onHover { isHovering in
                                    hoveredPlaylistId = isHovering ? playlist.id : nil
                                }
                                .onTapGesture {
                                    musicPlayer.selectedPlaylist = playlist
                                }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon & Name
            HStack(spacing: 12) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(width: 200, alignment: .leading)
            
            // Track Count
            Text("\(playlist.tracks.count)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            Spacer()
            
            // Source (YouTube / Local) - Mock logic for now based on ID presence
            Text(playlist.youtubePlaylistId != nil ? "YouTube" : "Local")
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle()) // Make full row tappable
    }
}

#Preview {
    PlaylistView()
        .environmentObject(MusicPlayerManager())
        .modelContainer(for: Playlist.self, inMemory: true)
}
