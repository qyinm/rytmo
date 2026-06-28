//
//  HomeView.swift
//  Pace
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var timerManager: PomodoroTimerManager
    
    var body: some View {
        VStack(spacing: 0) {
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
                    .accessibilityLabel("Reset timer")
                    .help("Discard the current session without saving")
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
                .accessibilityLabel(timerManager.session.isRunning ? "Pause timer" : "Start timer")
                .help(timerManager.session.isRunning ? "Pause the current session" : "Start or resume the focus timer")

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
                    .accessibilityLabel("Skip session")
                    .help("Save elapsed time and move to the next session paused")
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
    let settings = PomodoroSettings()

    HomeView()
        .environmentObject(PomodoroTimerManager(settings: settings))
        .environmentObject(settings)
        .environmentObject(MusicPlayerManager())
        .modelContainer(for: [FocusSession.self, TodoItem.self], inMemory: true)
        .frame(width: 1000, height: 700)
}
