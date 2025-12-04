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
            if let track = musicPlayer.currentTrack {
                Text(track.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
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
                .disabled(musicPlayer.selectedPlaylist == nil || musicPlayer.selectedPlaylist?.tracks.isEmpty == true)

                // Play/Pause button
                Button(action: {
                    musicPlayer.togglePlayPause()
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                }
                .buttonStyle(.plain)
                .disabled(musicPlayer.selectedPlaylist == nil || musicPlayer.selectedPlaylist?.tracks.isEmpty == true)

                // Next button
                Button(action: {
                    musicPlayer.playNextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .disabled(musicPlayer.selectedPlaylist == nil || musicPlayer.selectedPlaylist?.tracks.isEmpty == true)

                Spacer()

                // Volume slider
                HStack(spacing: 6) {
                    Image(systemName: musicPlayer.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Slider(value: Binding(
                        get: { musicPlayer.volume },
                        set: { musicPlayer.setVolume($0) }
                    ), in: 0...1)
                    .frame(width: 80)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MusicControllerView()
        .environmentObject(MusicPlayerManager())
        .padding()
        .frame(width: 340)
}
