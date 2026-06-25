//
//  AppActions.swift
//  rytmo
//

import Foundation

extension Notification.Name {
    static let showDashboard = Notification.Name("rytmo.showDashboard")
    static let openSettings = Notification.Name("rytmo.openSettings")
    static let dashboardNavigate = Notification.Name("rytmo.dashboardNavigate")
    static let timerTogglePlayPause = Notification.Name("rytmo.timerTogglePlayPause")
    static let timerSkip = Notification.Name("rytmo.timerSkip")
    static let timerReset = Notification.Name("rytmo.timerReset")
    static let createNewTask = Notification.Name("rytmo.createNewTask")
    static let createNewEvent = Notification.Name("rytmo.createNewEvent")
    static let togglePlayback = Notification.Name("rytmo.togglePlayback")
    static let toggleSidebar = Notification.Name("rytmo.toggleSidebar")
    static let focusNewTask = Notification.Name("rytmo.focusNewTask")
}

enum DashboardNavigationTarget: String {
    case home
    case calendar
    case tasks
    case playlists
    case settings
}