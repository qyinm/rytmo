import Testing
import SwiftUI
@testable import rytmo

@Suite("Calendar and timer regressions")
struct CalendarAndTimerRegressionTests {
    @Test("Google Calendar disconnect clears local auth and write state")
    @MainActor
    func googleCalendarDisconnectClearsLocalState() {
        let manager = GoogleCalendarManager.shared
        manager.isAuthorized = true
        manager.canWriteEvents = true
        manager.needsScopeUpgrade = true
        manager.isLoading = true
        manager.error = "stale"
        manager.availableCalendars = [
            CalendarInfo(
                id: "calendar-id",
                title: "Calendar",
                color: .blue,
                sourceTitle: "Google",
                type: .google
            )
        ]
        manager.events = [
            GoogleCalendarEvent(
                id: "event-id",
                summary: "Event",
                start: nil,
                end: nil,
                htmlLink: nil,
                colorId: nil,
                location: nil,
                description: nil,
                storedCalendarId: "calendar-id",
                storedCalendarColorHex: "#4285F4"
            )
        ]

        manager.disconnect(clearCache: false)

        #expect(manager.isAuthorized == false)
        #expect(manager.canWriteEvents == false)
        #expect(manager.needsScopeUpgrade == false)
        #expect(manager.isLoading == false)
        #expect(manager.error == nil)
        #expect(manager.availableCalendars.isEmpty)
        #expect(manager.events.isEmpty)
    }

    @Test("Skipping a running timer pauses on the next session without stale end date")
    @MainActor
    func skippingTimerStopsNextSession() {
        let settings = PomodoroSettings()
        let manager = PomodoroTimerManager(settings: settings)

        manager.start()
        manager.skip()

        #expect(manager.session.state == .shortBreak)
        #expect(manager.session.isRunning == false)
        #expect(manager.session.endDate == nil)
        #expect(manager.menuBarTitle == manager.session.formattedTime)
    }
}
