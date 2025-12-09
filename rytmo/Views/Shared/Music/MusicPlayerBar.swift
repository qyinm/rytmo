//
//  MusicPlayerBar.swift
//  rytmo
//
//  Created by hippoo on 12/9/25.
//

import SwiftUI

struct MusicPlayerBar: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 24) {
                // Track Info
                HStack(spacing: 12) {
                    // Artwork
                    if let thumbnailUrl = musicPlayer.currentTrack?.thumbnailUrl {
                        CachedAsyncImage(url: thumbnailUrl) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 48, height: 48)
                        .cornerRadius(6)
                        .clipped()
                    } else {
                        // Placeholder
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.secondary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = musicPlayer.playbackTitle ?? musicPlayer.currentTrack?.title {
                            Text(title)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                        } else {
                            Text("Not Playing")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Youtube Music")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 200, alignment: .leading)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 24) {
                    Button(action: { musicPlayer.playPreviousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)
                    
                    Button(action: { musicPlayer.togglePlayPause() }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)
                    
                    Button(action: { musicPlayer.playNextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)
                }
                
                Spacer()
                
                // Placeholder for Volume/Extra (to balance layout)
                HStack {
                     Spacer()
                }
                .frame(width: 200)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
    
    private var shouldDisableControls: Bool {
        guard let playlist = musicPlayer.selectedPlaylist else { return true }
        if playlist.youtubePlaylistId != nil { return false }
        return playlist.tracks.isEmpty
    }
}

#Preview {
    MusicPlayerBar()
        .environmentObject(MusicPlayerManager())
}
