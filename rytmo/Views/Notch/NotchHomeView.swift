//
//  NotchHomeView.swift
//  rytmo
//
//  Created by hippoo on 1/13/26.
//

import SwiftUI

struct NotchHomeView: View {
    @ObservedObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var vm: NotchViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            stateIcon
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(stateColor)
            
            if timerManager.session.state != .idle {
                Text(timerManager.session.formattedTime)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            if timerManager.session.isRunning {
                runningIndicator
            }
        }
        .frame(height: vm.effectiveClosedNotchHeight)
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
    
    @ViewBuilder
    private var runningIndicator: some View {
        Circle()
            .fill(stateColor)
            .frame(width: 6, height: 6)
            .opacity(timerManager.session.isRunning ? 1 : 0)
    }
}

#Preview {
    let settings = PomodoroSettings()
    let timerManager = PomodoroTimerManager(settings: settings)
    let vm = NotchViewModel()
    
    return NotchHomeView(timerManager: timerManager)
        .environmentObject(vm)
        .frame(width: 200, height: 32)
        .background(.black)
}
