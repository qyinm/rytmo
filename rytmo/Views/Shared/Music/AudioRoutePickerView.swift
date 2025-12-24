//
//  AudioRoutePickerView.swift
//  rytmo
//
//  Created by hippoo on 12/23/25.
//

import SwiftUI
import AVKit

// MARK: - Audio Route Picker View
/// 시스템 오디오 출력 장치를 선택할 수 있는 뷰 (AirPlay 등)
struct AudioRoutePickerView: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        // 아이콘 색상을 시스템 폰트 색상에 맞추기 위해 설정
        picker.isRoutePickerButtonBordered = false
        return picker
    }
    
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}

