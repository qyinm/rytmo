//
//  MusicPlayerBar.swift
//  rytmo
//
//  Created by hippoo on 12/9/25.
//

import SwiftUI

struct MusicPlayerBar: View {
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let seconds = Int(seconds)
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
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
                        .id(thumbnailUrl)
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
                VStack(spacing: 6) {
                HStack(spacing: 24) {
                    // Shuffle
                    Button(action: {
                        musicPlayer.isShuffle.toggle()
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 16))
                            .foregroundColor(musicPlayer.isShuffle ? .accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)

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
                    
                    // Repeat
                    Button(action: {
                        musicPlayer.repeatMode = musicPlayer.repeatMode.next()
                    }) {
                        Image(systemName: musicPlayer.repeatMode == .one ? "repeat.1" : "repeat")
                            .font(.system(size: 16))
                            .foregroundColor(musicPlayer.repeatMode != .off ? .accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)
                    .disabled(shouldDisableControls)
                }
                
                // Progress Bar
                HStack(spacing: 8) {
                    Text(formatTime(isDragging ? dragValue : musicPlayer.currentTime))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                    
                    Slider(
                        value: Binding(
                            get: { isDragging ? dragValue : musicPlayer.currentTime },
                            set: { newValue in
                                dragValue = newValue
                            }
                        ),
                        in: 0...max(musicPlayer.duration, 0.1),
                        onEditingChanged: { editing in
                            isDragging = editing
                            if !editing {
                                musicPlayer.seek(to: dragValue)
                            }
                        }
                    )
                    .controlSize(.small)
                    .disabled(shouldDisableControls)
                    
                    Text(formatTime(musicPlayer.duration))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .leading)
                }
                .frame(width: 320)
                }
                
                Spacer()
                
                // Volume Control
                HStack(spacing: 8) {
                    Image(systemName: musicPlayer.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            // Mute toggle logic could be added here
                            if musicPlayer.volume > 0 {
                                musicPlayer.setVolume(0)
                            } else {
                                musicPlayer.setVolume(50)
                            }
                        }
                    
                    Slider(
                        value: Binding(
                            get: { musicPlayer.volume },
                            set: { newValue in
                                musicPlayer.setVolume(newValue)
                            }
                        ),
                        in: 0...100
                    )
                    .controlSize(.mini)
                    .frame(width: 80)
                }
                .frame(width: 120, alignment: .trailing)
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
