//
//  PlaylistDetailView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    let playlist: Playlist
    var onBack: (() -> Void)? = nil
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @State private var hoveredTrackId: UUID?
    @State private var showingAddSong: Bool = false
    @State private var newSongUrl: String = ""
    
    // Sort tracks by sortIndex
    var sortedTracks: [MusicTrack] {
        playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Back Button
                if let onBack = onBack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Playlists")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 32)
                    .padding(.top, 24)
                }
                
                // Header Section
                VStack(alignment: .leading, spacing: 16) {
                    // Type Label
                    Text("PLAYLIST")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    // Playlist Title
                    Text(playlist.name)
                        .font(.system(size: 60, weight: .bold)) // Large title like reference
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    // Metadata line
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.caption)
                        Text("•")
                        Text("\(playlist.tracks.count) songs")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 32)
                .padding(.top, 40)
                .padding(.bottom, 24)
                
                // Action Bar (Play Button & Add Song)
                HStack(spacing: 24) {
                    Button(action: {
                        musicPlayer.selectedPlaylist = playlist
                        musicPlayer.togglePlayPause()
                    }) {
                        Image(systemName: isPlayingCurrentPlaylist ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.primary) // Black in light mode, White in dark
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingAddSong = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Song")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingAddSong) {
                        VStack(spacing: 16) {
                            Text("Add Song from YouTube")
                                .font(.headline)
                            
                            TextField("Paste YouTube URL", text: $newSongUrl)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 300)
                            
                            HStack {
                                Button("Cancel") {
                                    showingAddSong = false
                                    newSongUrl = ""
                                }
                                
                                Button("Add") {
                                    Task {
                                        await musicPlayer.addTrack(urlString: newSongUrl, to: playlist)
                                        newSongUrl = ""
                                        showingAddSong = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(newSongUrl.isEmpty)
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                // Track List Header
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 40, alignment: .center)
                    Text("TITLE")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                    
                    // Adding a spacer to push Delete button to far right
                    Spacer() 
                    
                    Text("") // Placeholder for delete button column
                        .frame(width: 40)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
                
                Divider()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 4)
                
                // Tracks
                if sortedTracks.isEmpty {
                    VStack(spacing: 12) {
                        Text("This playlist is empty")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Add songs from the home screen or Sidebar")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(sortedTracks.enumerated()), id: \.element.id) { index, track in
                            TrackRow(
                                index: index + 1,
                                track: track,
                                isHovered: hoveredTrackId == track.id,
                                isPlaying: musicPlayer.currentTrack?.id == track.id && musicPlayer.isPlaying,
                                onPlay: {
                                    musicPlayer.selectedPlaylist = playlist
                                    musicPlayer.play(track: track)
                                },
                                onDelete: {
                                    musicPlayer.deleteTrack(track)
                                }
                            )
                            .onHover { isHovering in
                                hoveredTrackId = isHovering ? track.id : nil
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var isPlayingCurrentPlaylist: Bool {
        musicPlayer.selectedPlaylist?.id == playlist.id && musicPlayer.isPlaying
    }
}

// MARK: - Subviews

private struct TrackRow: View {
    let index: Int
    let track: MusicTrack
    let isHovered: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Index / Play Icon Area
            ZStack {
                if isHovered || isPlaying {
                    Button(action: onPlay) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("\(index)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 40, alignment: .center)
            
            // Title & Info
            HStack(spacing: 12) {
                if let url = track.thumbnailUrl {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isPlaying ? Color.accentColor : Color.primary)
                        .lineLimit(1)
                    
                    Text("YouTube") // Placeholder for Artist/Album
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            
            Spacer()
            
            // Delete Action
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(width: 40)
            } else {
                Spacer().frame(width: 40)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle()) // Make full row hoverable
    }
}
