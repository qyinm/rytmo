//
//  NotchConstants.swift
//  rytmo
//
//  Created by hippoo on 1/13/26.
//  Reference: boring.notch sizing/matters.swift
//

import Foundation
import SwiftUI

// MARK: - Notch Sizing Constants

let shadowPadding: CGFloat = 20
let openNotchSize: CGSize = .init(width: 440, height: 360)
let windowSize: CGSize = .init(width: openNotchSize.width, height: openNotchSize.height + shadowPadding)

let cornerRadiusInsets: (opened: (top: CGFloat, bottom: CGFloat), closed: (top: CGFloat, bottom: CGFloat)) = (
    opened: (top: 19, bottom: 24),
    closed: (top: 6, bottom: 14)
)

// MARK: - Screen Helper Functions

@MainActor
func getScreenFrame(_ screenUUID: String? = nil) -> CGRect? {
    var selectedScreen = NSScreen.main
    
    if let uuid = screenUUID {
        selectedScreen = NSScreen.screen(withUUID: uuid)
    }
    
    if let screen = selectedScreen {
        return screen.frame
    }
    
    return nil
}

@MainActor
func getClosedNotchSize(screenUUID: String? = nil) -> CGSize {
    var notchHeight: CGFloat = 32
    var notchWidth: CGFloat = 185
    
    var selectedScreen = NSScreen.main
    
    if let uuid = screenUUID {
        selectedScreen = NSScreen.screen(withUUID: uuid)
    }
    
    if let screen = selectedScreen {
        if let topLeftNotchPadding: CGFloat = screen.auxiliaryTopLeftArea?.width,
           let topRightNotchPadding: CGFloat = screen.auxiliaryTopRightArea?.width {
            notchWidth = screen.frame.width - topLeftNotchPadding - topRightNotchPadding + 4
        }
        
        if screen.safeAreaInsets.top > 0 {
            notchHeight = screen.safeAreaInsets.top
        } else {
            notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
        }
    }
    
    return .init(width: notchWidth, height: notchHeight)
}

// MARK: - NSScreen Extension

extension NSScreen {
    static func screen(withUUID uuid: String) -> NSScreen? {
        return NSScreen.screens.first { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return false
            }
            if String(screenNumber) == uuid {
                return true
            }
            if let cfUUID = CGDisplayCreateUUIDFromDisplayID(screenNumber)?.takeRetainedValue(),
               let uuidString = CFUUIDCreateString(nil, cfUUID) as String? {
                return uuidString == uuid
            }
            return false
        }
    }
    
    var uuid: String? {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return nil
        }
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(screenNumber)?.takeRetainedValue() else {
            return nil
        }
        return CFUUIDCreateString(nil, cfUUID) as String?
    }
}
