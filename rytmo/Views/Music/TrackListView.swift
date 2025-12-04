//
//  TrackListView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI
import SwiftData

// MARK: - Track List View

struct TrackListView: View {

    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddTrack: Bool = false
    @State private var newTrackUrl: String = ""
    @State private var tracks: [MusicTrack] = []

    var body: some View {
        VStack(spacing: 0) {
            if musicPlayer.selectedPlaylist != nil {
                // Track list
                if tracks.isEmpty {
                    emptyState
                } else {
                    trackList
                }

                // Add track button
                addTrackButton
            } else {
                noPlaylistSelected
            }
        }
        .onChange(of: musicPlayer.selectedPlaylist) { _, newPlaylist in
            updateTracks(for: newPlaylist)
        }
        .onAppear {
            updateTracks(for: musicPlayer.selectedPlaylist)
        }
    }

    // MARK: - Track List

    private var trackList: some View {
        List {
            ForEach(tracks) { track in
                TrackRowView(
                    track: track,
                    isCurrentTrack: musicPlayer.currentTrack?.id == track.id,
                    isPlaying: musicPlayer.isPlaying,
                    onDelete: {
                        deleteTrack(track)
                    },
                    onTap: {
                        musicPlayer.play(track: track)
                    }
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                .listRowSeparator(.hidden)
            }
            .onMove(perform: moveTrack)
        }
        .listStyle(.plain)
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

    private var addTrackPopover: some View {
        VStack(spacing: 16) {
            Text("Add YouTube Track")
                .font(.headline)

            TextField("YouTube URL", text: $newTrackUrl)
                .textFieldStyle(.roundedBorder)
                .frame(width: 280)

            if let error = musicPlayer.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if musicPlayer.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    showingAddTrack = false
                    newTrackUrl = ""
                    musicPlayer.errorMessage = nil
                }
                .buttonStyle(.bordered)

                Button("Add") {
                    addTrack()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTrackUrl.isEmpty || musicPlayer.isLoading)
            }
        }
        .padding()
        .frame(width: 320)
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

    private func moveTrack(from source: IndexSet, to destination: Int) {
        tracks.move(fromOffsets: source, toOffset: destination)
        musicPlayer.reorderTracks(tracks)
    }
}

// MARK: - Preview

#Preview {
    TrackListView()
        .environmentObject(MusicPlayerManager())
        .frame(width: 340, height: 300)
}
