//
//  NotchViewModel.swift
//  rytmo
//
//  Created by hippoo on 1/13/26.
//  Reference: boring.notch BoringViewModel
//

import Combine
import SwiftUI

// MARK: - Notch State

enum NotchState {
    case open
    case closed
}

// MARK: - Notch View Model

@MainActor
class NotchViewModel: ObservableObject {
    
    // MARK: - Animation
    
    let animation: Animation = .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    
    // MARK: - Published Properties
    
    @Published private(set) var notchState: NotchState = .closed
    @Published var notchSize: CGSize = getClosedNotchSize()
    @Published var closedNotchSize: CGSize = getClosedNotchSize()
    @Published var screenUUID: String?
    @Published var isHovering: Bool = false
    
    // MARK: - Initialization
    
    init(screenUUID: String? = nil) {
        self.screenUUID = screenUUID
        self.notchSize = getClosedNotchSize(screenUUID: screenUUID)
        self.closedNotchSize = notchSize
    }
    
    // MARK: - Computed Properties
    
    var effectiveClosedNotchHeight: CGFloat {
        closedNotchSize.height
    }
    
    // MARK: - Public Methods
    
    func open() {
        notchSize = openNotchSize
        notchState = .open
    }
    
    func close() {
        notchSize = getClosedNotchSize(screenUUID: screenUUID)
        closedNotchSize = notchSize
        notchState = .closed
    }
    
    func toggle() {
        if notchState == .open {
            close()
        } else {
            open()
        }
    }
    
    func isMouseHovering(position: NSPoint = NSEvent.mouseLocation) -> Bool {
        let screenFrame = getScreenFrame(screenUUID)
        if let frame = screenFrame {
            let baseY = frame.maxY - notchSize.height
            let baseX = frame.midX - notchSize.width / 2
            
            return position.y >= baseY && position.x >= baseX && position.x <= baseX + notchSize.width
        }
        
        return false
    }
}
