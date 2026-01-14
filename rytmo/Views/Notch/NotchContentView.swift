//
//  NotchContentView.swift
//  rytmo
//
//  Created by hippoo on 1/13/26.
//  Reference: boring.notch ContentView
//

import SwiftUI

@MainActor
struct NotchContentView: View {
    @EnvironmentObject var vm: NotchViewModel
    @ObservedObject var timerManager: PomodoroTimerManager
    
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering: Bool = false
    
    private let animationSpring = Animation.spring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)
    
    private var topCornerRadius: CGFloat {
        vm.notchState == .open ? cornerRadiusInsets.opened.top : cornerRadiusInsets.closed.top
    }
    
    private var bottomCornerRadius: CGFloat {
        vm.notchState == .open ? cornerRadiusInsets.opened.bottom : cornerRadiusInsets.closed.bottom
    }
    
    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                notchContent
                    .frame(alignment: .top)
                    .padding(.horizontal, vm.notchState == .open ? cornerRadiusInsets.opened.bottom : 0)
                    .padding([.horizontal, .bottom], vm.notchState == .open ? 12 : 0)
                    .background(.black)
                    .clipShape(currentNotchShape)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .shadow(
                        color: (vm.notchState == .open || isHovering) ? .black.opacity(0.7) : .clear,
                        radius: 6
                    )
                    .frame(height: vm.notchState == .open ? vm.notchSize.height : vm.effectiveClosedNotchHeight)
                    .animation(animationSpring, value: vm.notchState)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        handleHover(hovering)
                    }
                    .onTapGesture {
                        doOpen()
                    }
            }
        }
        .padding(.bottom, 8)
        .frame(maxWidth: windowSize.width, maxHeight: windowSize.height, alignment: .top)
        .preferredColorScheme(.dark)
        .environmentObject(vm)
    }
    
    @ViewBuilder
    private var notchContent: some View {
        if vm.notchState == .open {
            NotchExpandedView(timerManager: timerManager)
        } else {
            NotchHomeView(timerManager: timerManager)
                .fixedSize()
        }
    }
    
    private func doOpen() {
        withAnimation(animationSpring) {
            vm.open()
        }
    }
    
    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        
        if hovering {
            withAnimation(animationSpring) {
                isHovering = true
            }
            
            guard vm.notchState == .closed else { return }
            
            if !vm.isMouseHovering() {
                return
            }
            
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard self.vm.notchState == .closed, self.isHovering else { return }
                    self.doOpen()
                }
            }
        } else {
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    withAnimation(animationSpring) {
                        self.isHovering = false
                    }
                    
                    if self.vm.notchState == .open {
                        withAnimation(animationSpring) {
                            self.vm.close()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let settings = PomodoroSettings()
    let timerManager = PomodoroTimerManager(settings: settings)
    let vm = NotchViewModel()
    
    return NotchContentView(timerManager: timerManager)
        .environmentObject(vm)
}
