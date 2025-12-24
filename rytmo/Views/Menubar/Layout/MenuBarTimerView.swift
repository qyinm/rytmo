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
    @EnvironmentObject var settings: PomodoroSettings
    
    var body: some View {
        HStack(spacing: 12) {
            // 왼쪽: 프로그레스 링 (더 작게)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 2.5)
                    .frame(width: 42, height: 42)
                
                Circle()
                    .trim(from: 0, to: timerManager.session.progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerManager.session.progress)
                
                // 상태 아이콘
                Image(systemName: stateIcon)
                    .font(.system(size: 12))
                    .foregroundColor(progressColor)
            }
            
            // 중앙: 시간 표시
            VStack(alignment: .leading, spacing: 1) {
                Text(timerManager.session.formattedTime)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                
                HStack(spacing: 5) {
                    Text(timerManager.session.state.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // 세션 카운터 (인라인)
                    if timerManager.session.state == .focus || timerManager.session.sessionCount > 0 {
                        HStack(spacing: 2.5) {
                            ForEach(0..<settings.sessionsBeforeLongBreak, id: \.self) { index in
                                Circle()
                                    .fill(index < timerManager.session.sessionCount ? progressColor : Color.gray.opacity(0.3))
                                    .frame(width: 3.5, height: 3.5)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // 오른쪽: 컨트롤 버튼들 (세로 배치)
            HStack(spacing: 8) {
                // 리셋 버튼
                if timerManager.session.isRunning || timerManager.session.state != .idle {
                    controlButton(
                        icon: "arrow.counterclockwise",
                        size: 26,
                        help: "리셋"
                    ) {
                        withAnimation { timerManager.reset() }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 재생/일시정지 버튼
                controlButton(
                    icon: timerManager.session.isRunning ? "pause.fill" : "play.fill",
                    size: 30,
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
                        size: 26,
                        help: "스킵"
                    ) {
                        withAnimation { timerManager.skip() }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        case .focus: return "flame.fill"
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

