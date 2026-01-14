import Foundation
import GoogleSignIn
import Combine
import SwiftUI

@MainActor
class GoogleCalendarManager: ObservableObject {
    static let shared = GoogleCalendarManager()
    
    @Published var events: [GoogleCalendarEvent] = []
    @Published var isAuthorized: Bool = false
    
    private let calendarScope = "https://www.googleapis.com/auth/calendar.readonly"
    
    private init() {}
    
    func checkPermission() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            let grantedScopes = user.grantedScopes ?? []
            self.isAuthorized = grantedScopes.contains(calendarScope)
            if self.isAuthorized {
                fetchEvents()
            }
        } else {
            self.isAuthorized = false
        }
    }
    
    func requestAccess() async {
        guard let window = NSApplication.shared.windows.first else { return }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: [calendarScope]
            )
            self.isAuthorized = result.user.grantedScopes?.contains(calendarScope) ?? false
            fetchEvents()
            print("✅ Google Calendar access granted via re-sign-in")
        } catch {
            print("❌ Google Calendar access request failed: \(error.localizedDescription)")
        }
    }
    
    func fetchEvents() {
        guard isAuthorized, let user = GIDSignIn.sharedInstance.currentUser else { return }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        
        // Fetch events for the next 24 hours
        let start = Date()
        let end = Calendar.current.date(byAdding: .hour, value: 24, to: start) ?? start.addingTimeInterval(24 * 3600)
        
        let isoFormatter = ISO8601DateFormatter()
        let timeMin = isoFormatter.string(from: start)
        let timeMax = isoFormatter.string(from: end)
        
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
                
                await MainActor.run {
                    self.events = response.items ?? []
                }
            } catch {
                print("❌ Failed to fetch Google Calendar events: \(error)")
            }
        }
    }
}

// MARK: - Models for Google Calendar API

struct GoogleCalendarListResponse: Codable {
    let items: [GoogleCalendarEvent]?
}

struct GoogleCalendarEvent: Codable, CalendarEventProtocol {
    let id: String
    let summary: String?
    let start: GoogleCalendarTime?
    let end: GoogleCalendarTime?
    let htmlLink: String?
    
    var eventIdentifier: String { id }
    var eventTitle: String? { summary }
    var eventStartDate: Date? { start?.dateValue }
    var eventEndDate: Date? { end?.dateValue }
    var eventColor: Color { .red } // Google Calendar default or fetch from API
    var sourceName: String { "Google" }
}

struct GoogleCalendarTime: Codable {
    let dateTime: String?
    let date: String?
    
    var dateValue: Date? {
        let formatter = ISO8601DateFormatter()
        if let dateTime = dateTime {
            return formatter.date(from: dateTime)
        } else if let date = date {
            // All-day event
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "yyyy-MM-dd"
            return dayFormatter.date(from: date)
        }
        return nil
    }
}
