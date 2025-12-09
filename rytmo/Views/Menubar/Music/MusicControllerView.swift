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
            }
        }
    }

    private var shouldDisableControls: Bool {
        return musicPlayer.selectedPlaylist == nil
    }
}

// MARK: - Preview

#Preview {
    MusicControllerView()
        .environmentObject(MusicPlayerManager())
        .padding()
        .frame(width: 340)
}