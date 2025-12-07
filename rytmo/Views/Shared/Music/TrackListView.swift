//
//  TrackListView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Track List View

struct TrackListView: View {

    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddTrack: Bool = false
    @State private var newTrackUrl: String = ""
    @State private var tracks: [MusicTrack] = []

    var body: some View {
        VStack(spacing: 0) {
            if let playlist = musicPlayer.selectedPlaylist {
                if playlist.youtubePlaylistId != nil && tracks.isEmpty {
                    youtubePlaylistState
                } else {
                    // Track list
                    if tracks.isEmpty {
                        emptyState
                    } else {
                        trackList
                    }

                    // Add track button (only for non-YT playlists or if we want to allow mixing)
                    if playlist.youtubePlaylistId == nil {
                        addTrackButton
                    }
                }
            } else {
                noPlaylistSelected
            }
        }
        .onChange(of: musicPlayer.selectedPlaylist) { _, newPlaylist in
            updateTracks(for: newPlaylist)
        }
        // Also watch for changes in the tracks array (e.g. after sync)
        .onChange(of: musicPlayer.selectedPlaylist?.tracks) { _, _ in
            updateTracks(for: musicPlayer.selectedPlaylist)
        }
        .onAppear {
            updateTracks(for: musicPlayer.selectedPlaylist)
        }
    }

    // MARK: - YouTube Playlist State

    private var youtubePlaylistState: some View {
        VStack(spacing: 8) {
            Image(systemName: "play.tv.fill")
                .font(.system(size: 32))
                .foregroundColor(.red.opacity(0.8))

            Text("Playing from YouTube Playlist")
                .font(.subheadline)
                .foregroundColor(.primary)

            Text("Tracks are managed by YouTube")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Track List

    private var trackList: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    TrackRowView(
                        track: track,
                        isCurrentTrack: musicPlayer.currentTrack?.id == track.id,
                        isPlaying: musicPlayer.isPlaying,
                        canMoveUp: index > 0,
                        canMoveDown: index < tracks.count - 1,
                        onDelete: {
                            deleteTrack(track)
                        },
                        onMoveUp: {
                            moveTrack(at: index, direction: -1)
                        },
                        onMoveDown: {
                            moveTrack(at: index, direction: 1)
                        },
                        onTap: {
                            musicPlayer.play(track: track)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No tracks yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Add a YouTube link to get started")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - No Playlist Selected

    private var noPlaylistSelected: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No playlist selected")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Create or select a playlist above")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - Add Track Button

    private var addTrackButton: some View {
        Button(action: {
            showingAddTrack = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Music Link")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .disabled(musicPlayer.selectedPlaylist == nil)
        .popover(isPresented: $showingAddTrack) {
            addTrackPopover
        }
    }

    // MARK: - Add Track Popover

    // MARK: - Add Track Popover

    private var addTrackPopover: some View {
        guard let playlist = musicPlayer.selectedPlaylist else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            AddYoutubeTrack(
                isPresented: $showingAddTrack,
                urlString: $newTrackUrl,
                playlist: playlist,
                onAdd: {
                    Task {
                        await musicPlayer.addTrack(urlString: newTrackUrl, to: playlist)
                        if musicPlayer.errorMessage == nil {
                            showingAddTrack = false
                            newTrackUrl = ""
                            updateTracks(for: playlist)
                        }
                    }
                }
            )
        )
    }

    // MARK: - Actions

    private func updateTracks(for playlist: Playlist?) {
        if let playlist = playlist {
            tracks = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
        } else {
            tracks = []
        }
    }

    private func addTrack() {
        guard let playlist = musicPlayer.selectedPlaylist else { return }

        Task {
            await musicPlayer.addTrack(urlString: newTrackUrl, to: playlist)

            if musicPlayer.errorMessage == nil {
                showingAddTrack = false
                newTrackUrl = ""
                updateTracks(for: playlist)
            }
        }
    }

    private func deleteTrack(_ track: MusicTrack) {
        musicPlayer.deleteTrack(track)
        updateTracks(for: musicPlayer.selectedPlaylist)
    }

    private func moveTrack(at index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < tracks.count else { return }

        withAnimation {
            let item = tracks.remove(at: index)
            tracks.insert(item, at: newIndex)
        }

        musicPlayer.reorderTracks(tracks)
    }
}

// MARK: - Preview

#Preview {
    TrackListView()
        .environmentObject(MusicPlayerManager())
        .frame(width: 340, height: 300)
}
