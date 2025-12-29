//
//  AudioRoutePickerView.swift
//  rytmo
//
//  Created by hippoo on 12/23/25.
//

import SwiftUI
import AVKit

// MARK: - Audio Route Picker View
/// View to select system audio output device (e.g., AirPlay)
struct AudioRoutePickerView: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        // Set to match icon color with system font color
        picker.isRoutePickerButtonBordered = false
        return picker
    }
    
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}

