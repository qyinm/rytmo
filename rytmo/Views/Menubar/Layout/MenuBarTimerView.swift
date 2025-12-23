//
//  MenuBarTimerView.swift
//  rytmo
//
//  Created by hippoo on 12/23/25.
//

import SwiftUI

// MARK: - Menu Bar Timer View
/// 메뉴바 전용 컴팩트한 가로형 타이머 뷰
struct MenuBarTimerView: View {
    
    @EnvironmentObject var timerManager: PomodoroTimerManager
    
    var body: some View {
        HStack(spacing: 16) {
            // 왼쪽: 프로그레스 링 (작게)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 3)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: timerManager.session.progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerManager.session.progress)
                
                // 상태 아이콘
                Image(systemName: stateIcon)
                    .font(.system(size: 14))
                    .foregroundColor(progressColor)
            }
            
            // 중앙: 시간 표시
            VStack(alignment: .leading, spacing: 2) {
                Text(timerManager.session.formattedTime)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(timerManager.session.state.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // 세션 카운터 (인라인)
                    if timerManager.session.state == .focus || timerManager.session.sessionCount > 0 {
                        HStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .fill(index < timerManager.session.sessionCount ? progressColor : Color.gray.opacity(0.3))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // 오른쪽: 컨트롤 버튼들 (세로 배치)
            HStack(spacing: 10) {
                // 리셋 버튼
                if timerManager.session.isRunning || timerManager.session.state != .idle {
                    controlButton(
                        icon: "arrow.counterclockwise",
                        size: 28,
                        help: "리셋"
                    ) {
                        withAnimation { timerManager.reset() }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 재생/일시정지 버튼
                controlButton(
                    icon: timerManager.session.isRunning ? "pause.fill" : "play.fill",
                    size: 32,
                    isPrimary: true,
                    help: timerManager.session.isRunning ? "일시정지" : "시작"
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if timerManager.session.isRunning {
                            timerManager.pause()
                        } else {
                            timerManager.start()
                        }
                    }
                }
                
                // 스킵 버튼
                if timerManager.session.state != .idle {
                    controlButton(
                        icon: "forward.fill",
                        size: 28,
                        help: "스킵"
                    ) {
                        withAnimation { timerManager.skip() }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
    
    // MARK: - Private Helpers
    
    private var progressColor: Color {
        switch timerManager.session.state {
        case .idle: return .gray
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
    
    private var stateIcon: String {
        switch timerManager.session.state {
        case .idle: return "moon.zzz.fill"
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
    
    private func controlButton(
        icon: String,
        size: CGFloat,
        isPrimary: Bool = false,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: isPrimary ? .bold : .semibold))
                .foregroundStyle(isPrimary ? .white : .primary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isPrimary ? Color.black : Color.primary.opacity(0.06))
                        .shadow(color: isPrimary ? Color.black.opacity(0.15) : .clear, radius: 4, y: 2)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// MARK: - Preview

#Preview {
    let settings = PomodoroSettings()
    let manager = PomodoroTimerManager(settings: settings)
    manager.session.state = .focus
    manager.session.remainingTime = 15 * 60
    manager.session.totalDuration = 25 * 60
    manager.session.sessionCount = 2
    
    return MenuBarTimerView()
        .environmentObject(manager)
        .environmentObject(settings)
        .frame(width: 480)
        .padding()
}

