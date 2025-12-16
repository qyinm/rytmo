//
//  PlaylistDetailView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    @Bindable var playlist: Playlist
    var onBack: (() -> Void)? = nil
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Environment(\.modelContext) private var modelContext
    @State private var hoveredTrackId: UUID?
    @State private var showingAddSong: Bool = false
    @State private var newSongUrl: String = ""
    
    // Playlist Management States
    @State private var showingRenameAlert = false
    @State private var showingDeleteAlert = false
    @State private var newPlaylistName = ""

    // Sync States
    @State private var isSyncing = false
    @State private var syncResultMessage: String?
    @State private var showingSyncResult = false
    
    // Sort tracks by sortIndex
    var sortedTracks: [MusicTrack] {
        playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
    }
    
    var body: some View {
        List {
            // MARK: - Header Section (Non-scrollable relative to list, but part of list content)
            Group {
                VStack(alignment: .leading, spacing: 0) {
                    // Back Button & Menu
                    HStack {
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
                        }
                        
                        Spacer()
                        
                        // Playlist Menu
                        Menu {
                            Button {
                                newPlaylistName = playlist.name
                                showingRenameAlert = true
                            } label: {
                                Label("Rename Playlist", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Playlist", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    // Playlist Metadata
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PLAYLIST")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        Text(playlist.name)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "music.note")
                                .font(.caption)
                            Text("•")
                            Text("\(playlist.tracks.count) songs")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 24)
                    
                    // Action Buttons
                    HStack(spacing: 24) {
                        Button(action: {
                            musicPlayer.playPlaylist(playlist)
                        }) {
                            Image(systemName: isPlayingCurrentPlaylist ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.primary)
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
                            AddYoutubeTrack(
                                isPresented: $showingAddSong,
                                urlString: $newSongUrl,
                                playlist: playlist
                            )
                        }

                        // Sync button (only for YouTube playlists)
                        if playlist.youtubePlaylistId != nil {
                            Button(action: {
                                Task {
                                    await syncPlaylist()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 14))
                                    }
                                    Text(isSyncing ? "Syncing..." : "Sync")
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
                            .disabled(isSyncing)
                        }

                        Spacer()
                    }
                    .padding(.bottom, 32)
                    
                    // Track List Columns Header
                    HStack(spacing: 0) {
                        Text("#")
                            .frame(width: 40, alignment: .center)
                        Text("TITLE")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 12)
                        Spacer()
                        Text("")
                            .frame(width: 40)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                    
                    Divider()
                }
                .padding(.horizontal, 32)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .background(Color(nsColor: .windowBackgroundColor))
            
            // MARK: - Track List
            if sortedTracks.isEmpty {
                Group {
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
                    .listRowSeparator(.hidden)
                }
            } else {
                ForEach(sortedTracks, id: \.id) { track in
                    TrackRow(
                        index: track.sortIndex + 1,
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
                    // Context Menu for individual track actions
                    .contextMenu {
                        Button(role: .destructive) {
                            musicPlayer.deleteTrack(track)
                        } label: {
                            Label("Delete Song", systemImage: "trash")
                        }
                    }
                    // For macOS standard list reorder
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .onMove(perform: moveTracks)
            }
        }
        .listStyle(.plain)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Rename Playlist", isPresented: $showingRenameAlert) {
            TextField("Name", text: $newPlaylistName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                playlist.name = newPlaylistName
                try? modelContext.save()
            }
        }
        .alert("Delete Playlist?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                musicPlayer.deletePlaylist(playlist)
                onBack?()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Sync Complete", isPresented: $showingSyncResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(syncResultMessage ?? "")
        }
    }

    private var isPlayingCurrentPlaylist: Bool {
        musicPlayer.selectedPlaylist?.id == playlist.id && musicPlayer.isPlaying
    }

    private func moveTracks(from source: IndexSet, to destination: Int) {
        var tracks = sortedTracks
        tracks.move(fromOffsets: source, toOffset: destination)
        musicPlayer.reorderTracks(tracks)
    }

    private func syncPlaylist() async {
        isSyncing = true

        let result = await musicPlayer.addMissingTracksFromYouTube(playlist)

        isSyncing = false

        if result.success {
            if result.newTracksCount > 0 {
                syncResultMessage = "Successfully synced! Added \(result.newTracksCount) new track(s)."
            } else {
                syncResultMessage = "Playlist is already up to date."
            }
        } else {
            syncResultMessage = "Failed to sync playlist. Please try again."
        }

        showingSyncResult = true
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
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("YouTube")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            
            Spacer()
            
            // Delete Action (Visual Button + Context Menu support via parent)
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
        .contentShape(Rectangle())
    }
}
