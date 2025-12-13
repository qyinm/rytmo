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

    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0
    @State private var isVolumePopoverPresented: Bool = false

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let seconds = Int(seconds)
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

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
                .controlSize(.mini)
                .disabled(shouldDisableControls)
                
                Text(formatTime(musicPlayer.duration))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .leading)
            }
            .padding(.horizontal, 8)

            ZStack {
                // Center: Playback Controls
                HStack(spacing: 20) {
                    // Shuffle
                    Button(action: { musicPlayer.isShuffle.toggle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 14))
                            .foregroundColor(musicPlayer.isShuffle ? .accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)

                    // Previous
                    Button(action: { musicPlayer.playPreviousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)

                    // Play/Pause
                    Button(action: { musicPlayer.togglePlayPause() }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)

                    // Next
                    Button(action: { musicPlayer.playNextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)

                    // Repeat
                    Button(action: {
                        musicPlayer.repeatMode = musicPlayer.repeatMode.next()
                    }) {
                        Image(systemName: musicPlayer.repeatMode == .one ? "repeat.1" : "repeat")
                            .font(.system(size: 14))
                            .foregroundColor(musicPlayer.repeatMode != .off ? .accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)
                }
                
                // Right: Volume Button
                HStack {
                    Spacer()
                    Button(action: { isVolumePopoverPresented.toggle() }) {
                        Image(systemName: musicPlayer.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isVolumePopoverPresented, arrowEdge: .bottom) {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
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
                            .frame(width: 100)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                    }
                }
            }
            .padding(.horizontal, 16)
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