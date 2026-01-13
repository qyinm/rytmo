//
//  NotchExpandedView.swift
//  rytmo
//
//  Created by hippoo on 1/13/26.
//

import SwiftUI

struct NotchExpandedView: View {
    @ObservedObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var vm: NotchViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            
            timerDisplay
            
            controlButtons
            
            sessionIndicator
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text(timerManager.session.state.displayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            stateIcon
                .font(.system(size: 14))
                .foregroundColor(stateColor)
        }
    }
    
    @ViewBuilder
    private var stateIcon: some View {
        switch timerManager.session.state {
        case .idle:
            Image(systemName: "clock")
        case .focus:
            Image(systemName: "brain.head.profile")
        case .shortBreak:
            Image(systemName: "cup.and.saucer")
        case .longBreak:
            Image(systemName: "figure.walk")
        }
    }
    
    private var stateColor: Color {
        switch timerManager.session.state {
        case .idle:
            return .gray
        case .focus:
            return .orange
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
    
    // MARK: - Timer Display
    
    @ViewBuilder
    private var timerDisplay: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: timerManager.session.progress)
                .stroke(stateColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: timerManager.session.progress)
            
            VStack(spacing: 4) {
                Text(timerManager.session.formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                if timerManager.session.isRunning {
                    Text("Running")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(stateColor)
                } else if timerManager.session.state != .idle {
                    Text("Paused")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 180, height: 180)
    }
    
    // MARK: - Control Buttons
    
    @ViewBuilder
    private var controlButtons: some View {
        HStack(spacing: 24) {
            Button(action: { timerManager.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Button(action: {
                if timerManager.session.isRunning {
                    timerManager.pause()
                } else {
                    timerManager.start()
                }
            }) {
                Image(systemName: timerManager.session.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 60, height: 60)
                    .background(stateColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Button(action: { timerManager.skip() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Session Indicator
    
    @ViewBuilder
    private var sessionIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < timerManager.session.sessionCount ? stateColor : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    let settings = PomodoroSettings()
    let timerManager = PomodoroTimerManager(settings: settings)
    let vm = NotchViewModel()
    
    return NotchExpandedView(timerManager: timerManager)
        .environmentObject(vm)
        .frame(width: 400, height: 340)
        .background(.black)
}
