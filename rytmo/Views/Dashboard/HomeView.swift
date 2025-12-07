//
//  HomeView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI

//
//  HomeView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import YouTubePlayerKit

struct HomeView: View {
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            HStack(spacing: 0) {
                // Left: Timer (Center)
                VStack {
                    Spacer()
                    
                    // Timer UI
                    VStack(spacing: 32) {
                        TimerView()
                            .scaleEffect(1.2)
                        
                        // Timer Controls
                        HStack(spacing: 20) {
                            Button(action: {
                                if timerManager.session.isRunning {
                                    timerManager.pause()
                                } else {
                                    timerManager.start()
                                }
                            }) {
                                Image(systemName: timerManager.session.isRunning ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .frame(width: 60, height: 60)
                                    .background(timerManager.session.isRunning ? Color.orange : Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .buttonStyle(.plain)
                            
                            // Skip Button
                            if timerManager.session.state != .idle {
                                Button(action: {
                                    timerManager.skip()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .help("Skip current session")
                            }
                            
                            // Reset Button
                            if timerManager.session.isRunning || timerManager.session.state != .idle {
                                Button(action: {
                                    timerManager.reset()
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .help("Reset timer")
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
                
                // Right: Playlist & Tracks Sidebar
                VStack(spacing: 0) {
                    Text("Library")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Playlist Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Playlists")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                PlaylistSelectorView()
                            }
                            
                            Divider()
                            
                            // Track List
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tracks")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TrackListView()
                            }
                        }
                        .padding()
                    }
                }
                .frame(width: 320)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                .overlay(
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(width: 1),
                    alignment: .leading
                )
            }
            
            // Bottom: Music Player Bar
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 24) {
                    // Track Info
                    HStack(spacing: 12) {
                        // Artwork Placeholder
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.secondary)
                            )
                        
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
                            
                            // Artist info not available in MusicTrack model yet
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
                .background(Color(nsColor: .controlBackgroundColor)) // Slightly different bg for bar
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        // Hidden Player for Logic

    }
    
    private var shouldDisableControls: Bool {
        guard let playlist = musicPlayer.selectedPlaylist else { return true }
        if playlist.youtubePlaylistId != nil { return false }
        return playlist.tracks.isEmpty
    }
}

#Preview {
    HomeView()
        .environmentObject(PomodoroTimerManager(settings: PomodoroSettings()))
        .environmentObject(MusicPlayerManager())
        .frame(width: 800, height: 600)
}
