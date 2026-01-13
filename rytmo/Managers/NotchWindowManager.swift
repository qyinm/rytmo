//
//  NotchWindowManager.swift
//  rytmo
//
//  Created on 2025.
//

import AppKit
import Combine
import SwiftUI

@MainActor
class NotchWindowManager: NSObject, ObservableObject {
    static let shared = NotchWindowManager()
    
    private var window: NSWindow?
    private var previousScreens: [NSScreen]?
    private let coordinator = NotchCoordinator.shared
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
    }
    
    func setup<Content: View>(with content: Content) {
        setupNotifications()
        createWindow(with: content)
        adjustWindowPosition(changeAlpha: true)
        previousScreens = NSScreen.screens
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            forName: .selectedScreenChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.adjustWindowPosition(changeAlpha: true)
            }
        }
    }
    
    private func createWindow<Content: View>(with content: Content) {
        let windowSize = UIConstants.Notch.windowSize
        let rect = NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height)
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow]
        
        let panel = NSPanel(
            contentRect: rect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        panel.level = .mainMenu + 1
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        
        let hostingView = NSHostingView(rootView: content)
        panel.contentView = hostingView
        
        panel.orderFrontRegardless()
        
        self.window = panel
    }
    
    @objc private func screenConfigurationDidChange() {
        let currentScreens = NSScreen.screens
        
        let screensChanged =
            currentScreens.count != previousScreens?.count
            || Set(currentScreens.compactMap { $0.displayUUID })
                != Set(previousScreens?.compactMap { $0.displayUUID } ?? [])
            || Set(currentScreens.map { $0.frame }) != Set(previousScreens?.map { $0.frame } ?? [])
        
        previousScreens = currentScreens
        
        if screensChanged {
            adjustWindowPosition()
        }
    }
    
    func adjustWindowPosition(changeAlpha: Bool = false) {
        guard let window = window else { return }
        
        let selectedScreen: NSScreen
        
        if let preferredScreen = NSScreen.screen(withUUID: coordinator.preferredScreenUUID ?? "") {
            coordinator.selectedScreenUUID = coordinator.preferredScreenUUID ?? ""
            selectedScreen = preferredScreen
        } else if let mainScreen = NSScreen.main {
            coordinator.selectedScreenUUID = mainScreen.displayUUID ?? ""
            selectedScreen = mainScreen
        } else {
            window.alphaValue = 0
            return
        }
        
        positionWindow(window, on: selectedScreen, changeAlpha: changeAlpha)
    }
    
    private func positionWindow(_ window: NSWindow, on screen: NSScreen, changeAlpha: Bool = false) {
        if changeAlpha {
            window.alphaValue = 0
        }
        
        let screenFrame = screen.frame
        let windowFrame = window.frame
        
        let x = screenFrame.origin.x + (screenFrame.width / 2) - (windowFrame.width / 2)
        let y = screenFrame.origin.y + screenFrame.height - windowFrame.height
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
        window.alphaValue = 1
    }
    
    func updateWindowSize(_ size: CGSize) {
        guard let window = window else { return }
        
        var frame = window.frame
        let oldHeight = frame.height
        
        frame.size = size
        frame.origin.y += oldHeight - size.height
        
        window.setFrame(frame, display: true, animate: false)
    }
    
    func showWindow() {
        window?.orderFrontRegardless()
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
    
    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        window?.close()
        window = nil
    }
}
