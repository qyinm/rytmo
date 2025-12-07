//
//  MusicSectionView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI
import YouTubePlayerKit

// MARK: - Music Section View

/// Combined view for music player functionality
struct MusicSectionView: View {

    @EnvironmentObject var musicPlayer: MusicPlayerManager

    var body: some View {
        VStack(spacing: 16) {
            // Hidden YouTube Player (for audio playback)
            YouTubePlayerView(musicPlayer.youTubePlayer)
                .frame(width: 1, height: 1)
                .opacity(0)

            // Playlist selector
            PlaylistSelectorView()

            // Music controller
            MusicControllerView()

            Divider()

            // Track list
            TrackListView()
        }
    }
}

// MARK: - Preview

#Preview {
    MusicSectionView()
        .environmentObject(MusicPlayerManager())
        .padding()
        .frame(width: 360, height: 400)
}
