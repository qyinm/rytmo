//
//  MusicControllerView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI

// MARK: - Music Controller View

struct MusicControllerView: View {

    @EnvironmentObject var musicPlayer: MusicPlayerManager

    var body: some View {
        VStack(spacing: 12) {
            // Current track title
            if let title = musicPlayer.playbackTitle ?? musicPlayer.currentTrack?.title {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text(" ") // Placeholder to keep height
                    .font(.caption)
            }

            HStack(spacing: 16) {
                // Shuffle button
                Button(action: {
                    musicPlayer.isShuffle.toggle()
                }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14))
                        .foregroundColor(musicPlayer.isShuffle ? .accentColor : .primary)
                }
                .buttonStyle(.plain)
                .disabled(shouldDisableControls)

                // Previous button
                Button(action: {
                    musicPlayer.playPreviousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .disabled(shouldDisableControls)

                // Play/Pause button
                Button(action: {
                    musicPlayer.togglePlayPause()
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                }
                .buttonStyle(.plain)
                .disabled(shouldDisableControls)

                // Next button
                Button(action: {
                    musicPlayer.playNextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .disabled(shouldDisableControls)

                // Repeat button
                Button(action: {
                    switch musicPlayer.repeatMode {
                    case .off: musicPlayer.repeatMode = .all
                    case .all: musicPlayer.repeatMode = .one
                    case .one: musicPlayer.repeatMode = .off
                    }
                }) {
                    Image(systemName: musicPlayer.repeatMode == .one ? "repeat.1" : "repeat")
                        .font(.system(size: 14))
                        .foregroundColor(musicPlayer.repeatMode != .off ? .accentColor : .primary)
                }
                .buttonStyle(.plain)
                .disabled(shouldDisableControls)
            }
        }
    }

    private var shouldDisableControls: Bool {
        guard let playlist = musicPlayer.selectedPlaylist else { return true }
        if playlist.youtubePlaylistId != nil { return false }
        return playlist.tracks.isEmpty
    }
}

// MARK: - Preview

#Preview {
    MusicControllerView()
        .environmentObject(MusicPlayerManager())
        .padding()
        .frame(width: 340)
}