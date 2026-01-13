import SwiftUI

struct NotchHomeView: View {
    @ObservedObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var vm: NotchViewModel
    
    var body: some View {
        ZStack {
            if timerManager.session.state.displayName != "Idle" {
                HStack(spacing: 0) {
                    Text(timerManager.session.formattedTime)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.leading, 12)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                    Spacer()
                    
                    runningIndicator
                        .opacity(timerManager.session.isRunning ? 1.0 : 0.4)
                        .padding(.trailing, 12)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            
            stateIcon
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(stateColor)
                .scaleEffect(timerManager.session.isRunning ? 1.0 : 0.9)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timerManager.session.isRunning)
        }
        .frame(width: vm.closedNotchSize.width + (timerManager.session.state.displayName != "Idle" ? 100 : 0))
        .frame(height: vm.effectiveClosedNotchHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerManager.session.state.displayName)
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
        case .focus:
            return .orange
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        default:
            return .gray
        }
    }
    
    @ViewBuilder
    private var runningIndicator: some View {
        Circle()
            .fill(stateColor)
            .frame(width: 6, height: 6)
    }
}
