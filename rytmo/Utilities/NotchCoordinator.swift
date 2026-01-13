//
//  NotchCoordinator.swift
//  rytmo
//
//  Created on 2025.
//

import AppKit
import Combine
import SwiftUI

enum NotchView {
    case home
    case timer
    case dashboard
    case settings
}

@MainActor
class NotchCoordinator: ObservableObject {
    static let shared = NotchCoordinator()
    
    @Published var currentView: NotchView = .home
    @Published var isExpanded: Bool = false
    
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    @AppStorage("preferred_screen_uuid") var preferredScreenUUID: String? {
        didSet {
            if let uuid = preferredScreenUUID {
                selectedScreenUUID = uuid
            }
            NotificationCenter.default.post(name: .selectedScreenChanged, object: nil)
        }
    }
    
    @Published var selectedScreenUUID: String = ""
    
    private init() {
        if preferredScreenUUID == nil {
            preferredScreenUUID = NSScreen.main?.displayUUID
        }
        selectedScreenUUID = preferredScreenUUID ?? NSScreen.main?.displayUUID ?? ""
    }
    
    func expand() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = true
        }
    }
    
    func collapse() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
    
    func toggle() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    func showHome() {
        currentView = .home
    }
    
    func showTimer() {
        currentView = .timer
    }
    
    func showDashboard() {
        currentView = .dashboard
    }
    
    func showSettings() {
        currentView = .settings
    }
}

extension NSScreen {
    var displayUUID: String? {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return nil
        }
        return String(screenNumber)
    }
}

extension Notification.Name {
    static let selectedScreenChanged = Notification.Name("SelectedScreenChanged")
    static let notchStateChanged = Notification.Name("NotchStateChanged")
}
