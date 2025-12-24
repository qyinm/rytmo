//
//  LiveWaveformView.swift
//  rytmo
//
//  Created by hippoo on 12/23/25.
//

import SwiftUI
import Combine

// MARK: - Live Waveform View
/// 오디오 재생 상태에 따라 동적으로 움직이는 파형 뷰
struct LiveWaveformView: View {
    let isPlaying: Bool
    let color: Color
    let barCount: Int = 5
    
    @State private var barHeights: [CGFloat] = Array(repeating: 0.2, count: 5)
    @State private var timerSubscription: AnyCancellable? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 2, height: isPlaying ? barHeights[index] * 16 : 2)
                    .animation(.easeInOut(duration: 0.15), value: barHeights[index])
            }
        }
        .frame(height: 16)
        .onAppear {
            if isPlaying {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        guard timerSubscription == nil else { return }
        timerSubscription = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateHeights()
            }
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    private func updateHeights() {
        for i in 0..<barCount {
            // 랜덤하게 높이 조절 (0.3 ~ 1.0 사이)
            barHeights[i] = CGFloat.random(in: 0.3...1.0)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        LiveWaveformView(isPlaying: true, color: .blue)
        LiveWaveformView(isPlaying: false, color: .gray)
    }
    .padding()
}

