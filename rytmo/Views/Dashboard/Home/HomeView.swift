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
                    
                    // Playlist Selector Section (Fixed)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playlists")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            PlaylistSelectorView()
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    // Track List Section (Scrollable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tracks")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView {
                            TrackListView()
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                    .padding(.top)
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
            
        }
        .background(Color(nsColor: .windowBackgroundColor))
        // Hidden Player for Logic

    }
}

#Preview {
    HomeView()
        .environmentObject(PomodoroTimerManager(settings: PomodoroSettings()))
        .environmentObject(MusicPlayerManager())
        .frame(width: 800, height: 600)
}
