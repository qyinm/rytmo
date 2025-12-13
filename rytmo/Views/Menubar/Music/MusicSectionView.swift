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
            // Playlist selector
            PlaylistSelectorView()

            // Music controller
            MusicControllerView()

            Divider()

            // Track list
            TrackListView(isMenuBar: true)
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
