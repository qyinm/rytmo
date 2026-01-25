import SwiftUI

struct NotchHomeView: View {
    @ObservedObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var musicPlayer: MusicPlayerManager
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
                }
            }
            
            HStack(spacing: 0) {
                Spacer()
                
                if musicPlayer.isPlaying || musicPlayer.currentTrack != nil {
                    MusicVisualizerView(musicPlayer: musicPlayer)
                        .padding(.trailing, 12)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else if timerManager.session.state.displayName != "Idle" {
                    runningIndicator
                        .opacity(timerManager.session.isRunning ? 1.0 : 0.4)
                        .padding(.trailing, 12)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .frame(width: vm.closedNotchSize.width + expandedWidth)
        .frame(height: vm.effectiveClosedNotchHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerManager.session.state.displayName)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: musicPlayer.isPlaying)
    }
    
    private var expandedWidth: CGFloat {
        let isTimerActive = timerManager.session.state.displayName != "Idle"
        let isMusicActive = musicPlayer.isPlaying || musicPlayer.currentTrack != nil
        
        if isTimerActive || isMusicActive {
            return 130
        }
        return 0
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
