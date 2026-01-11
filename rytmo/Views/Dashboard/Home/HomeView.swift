//
//  HomeView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData
import YouTubePlayerKit

struct HomeView: View {
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @State private var rightSidebarSelection: Int = 0 // 0: Library, 1: Tasks
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            HStack(spacing: 0) {
                // Left: Dashboard Grid
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        timerCard
                        FocusStatsView()
                            .frame(maxWidth: 300)
                    }
                    
                    FocusRecordsView()
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
    
    // MARK: - Timer Card
    
    private var timerCard: some View {
        VStack(spacing: 24) {
            TimerView()
                .scaleEffect(1.0)
            
            // Timer Controls
            HStack(spacing: 20) {
                // Reset Button
                if timerManager.session.isRunning || timerManager.session.state != .idle {
                    Button(action: {
                        withAnimation { timerManager.reset() }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
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
                    Color.clear.frame(width: 36, height: 36)
                }
                
                // Play/Pause Button
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
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: timerManager.session.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Skip Button
                if timerManager.session.state != .idle {
                    Button(action: {
                        withAnimation { timerManager.skip() }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
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
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            .animation(.spring(), value: timerManager.session.state)
            .animation(.spring(), value: timerManager.session.isRunning)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(PomodoroTimerManager(settings: PomodoroSettings()))
        .environmentObject(MusicPlayerManager())
        .modelContainer(for: FocusSession.self, inMemory: true)
        .frame(width: 1000, height: 700)
}
