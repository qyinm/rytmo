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
    @State private var rightSidebarSelection: Int = 0 // 0: Library, 1: Tasks
    
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
                        HStack(spacing: 24) {
                            // Reset Button (Left)
                            if timerManager.session.isRunning || timerManager.session.state != .idle {
                                Button(action: {
                                    withAnimation {
                                        timerManager.reset()
                                    }
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                                .background(Circle().fill(Color.primary.opacity(0.05)))
                                        )
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                                .help("Reset timer")
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                // Placeholder to keep layout balanced if needed, or just Spacer
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                            
                            // Play/Pause Button (Center)
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if timerManager.session.isRunning {
                                        timerManager.pause()
                                    } else {
                                        timerManager.start()
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 72, height: 72)
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    
                                    Image(systemName: timerManager.session.isRunning ? "pause.fill" : "play.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            // Skip Button (Right)
                            if timerManager.session.state != .idle {
                                Button(action: {
                                    withAnimation {
                                        timerManager.skip()
                                    }
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                                .background(Circle().fill(Color.primary.opacity(0.05)))
                                        )
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                                .help("Skip current session")
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .animation(.spring(), value: timerManager.session.state)
                        .animation(.spring(), value: timerManager.session.isRunning)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
                
                // Right: Sidebar (Library & Tasks)
                VStack(spacing: 0) {
                    // Selection Header
                    HStack(spacing: 0) {
                        Button {
                            rightSidebarSelection = 0
                        } label: {
                            VStack(spacing: 8) {
                                Text("Library")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(rightSidebarSelection == 0 ? .primary : .secondary)
                                
                                Rectangle()
                                    .fill(rightSidebarSelection == 0 ? Color.accentColor : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        
                        Button {
                            rightSidebarSelection = 1
                        } label: {
                            VStack(spacing: 8) {
                                Text("Tasks")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(rightSidebarSelection == 1 ? .primary : .secondary)
                                
                                Rectangle()
                                    .fill(rightSidebarSelection == 1 ? Color.accentColor : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 16)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    
                    Divider()
                    
                    if rightSidebarSelection == 0 {
                        // Library Content
                        VStack(spacing: 0) {
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
                    } else {
                        // Tasks Content
                        VStack(alignment: .leading, spacing: 16) {
                            TodoListView(showHeader: false, compact: true)
                                .padding()
                            
                            Spacer()
                        }
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
            
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    HomeView()
        .environmentObject(PomodoroTimerManager(settings: PomodoroSettings()))
        .environmentObject(MusicPlayerManager())
        .frame(width: 800, height: 600)
}
