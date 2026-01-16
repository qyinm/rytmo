import Foundation
import GoogleSignIn
import Combine
import SwiftUI
import FirebaseCore
import EventKit

// MARK: - Constants

private enum GoogleCalendarAPI {
    static let scope = "https://www.googleapis.com/auth/calendar.readonly"
    static let baseURL = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
    static let signInErrorDomain = "com.google.GIDSignIn"
    static let cancelledErrorCode = -5
}

@MainActor
class GoogleCalendarManager: ObservableObject {
    static let shared = GoogleCalendarManager()
    
    @Published var events: [GoogleCalendarEvent] = []
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @AppStorage("calendar_event_range_hours") private var eventRangeHours: Int = 24
    
    private init() {}
    
    // MARK: - Permission Check
    
    func checkPermission() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            let grantedScopes = user.grantedScopes ?? []
            self.isAuthorized = grantedScopes.contains(GoogleCalendarAPI.scope)
            if self.isAuthorized {
                // Automatically fetch events when permission is confirmed
                fetchEvents()
            }
        } else {
            self.isAuthorized = false
        }
    }
    
    // MARK: - Token Refresh
    
    /// Refresh access token if needed before making API calls
    private func refreshTokenIfNeeded() async -> Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            self.error = "Google user not found. Please sign in again."
            return false
        }
        
        do {
            // This will refresh the token if it's expired
            try await user.refreshTokensIfNeeded()
            return true
        } catch {
            print("❌ Token refresh failed: \(error.localizedDescription)")
            self.error = "Failed to refresh token: \(error.localizedDescription)"
            self.isAuthorized = false
            return false
        }
    }
    
    // MARK: - Request Access
    
    func requestAccess() async {
        guard let window = NSApplication.shared.windows.first else {
            self.error = "Cannot find window to present sign-in"
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        // Always configure Google Sign-In before making the call
        // (configuration might exist but be invalid)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.isLoading = false
            self.error = "Firebase Client ID not found"
            print("❌ Critical: Firebase Client ID not found, cannot configure Google Sign-In")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: [GoogleCalendarAPI.scope]
            )
            
            self.isAuthorized = result.user.grantedScopes?.contains(GoogleCalendarAPI.scope) ?? false
            
            if self.isAuthorized {
                print("✅ Google Calendar access granted")
                fetchEvents()
            } else {
                self.error = "Calendar permission was not granted"
            }
        } catch let error as NSError {
            // Handle cancellation gracefully
            if error.domain == GoogleCalendarAPI.signInErrorDomain && error.code == GoogleCalendarAPI.cancelledErrorCode {
                print("ℹ️ Google Calendar sign-in cancelled")
                // Don't set error for user cancellation
            } else {
                self.error = "Sign-in failed: \(error.localizedDescription)"
                print("❌ Google Calendar access request failed: \(error.localizedDescription)")
            }
        }
        
        self.isLoading = false
    }
    
    // MARK: - Disconnect
    
    /// Disconnect Google Calendar integration (without signing out of Google account)
    func disconnect() {
        self.isAuthorized = false
        self.events = []
        self.error = nil
        print("ℹ️ Google Calendar disconnected")
    }
    
    // MARK: - Fetch Events
    
    func fetchEvents(date: Date = Date()) {
        guard isAuthorized else { return }
        
        self.isLoading = true
        self.error = nil
        
        Task {
            // Refresh token before making API call
            guard await refreshTokenIfNeeded() else {
                self.isLoading = false
                return
            }
            
            guard let user = GIDSignIn.sharedInstance.currentUser else {
                self.isLoading = false
                self.error = "User not found"
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let urlString = GoogleCalendarAPI.baseURL
            
            // Fetch events for the full month of the provided date
            let calendar = Calendar.current
            guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
                self.isLoading = false
                return
            }
            
            // Extend range to include padding days for grid view (start of first week to end of last week)
            let monthDays = CalendarUtils.generateDaysInMonth(for: date)
            let start = monthDays.first ?? monthInterval.start
            let end = calendar.date(byAdding: .day, value: 1, to: monthDays.last ?? monthInterval.end) ?? monthInterval.end
            
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
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check for HTTP errors
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 {
                        // Token might be invalid, try to refresh and retry once
                        self.isAuthorized = false
                        self.error = "Session expired. Please reconnect Google Calendar."
                        self.isLoading = false
                        return
                    } else if httpResponse.statusCode != 200 {
                        self.error = "Failed to fetch events (HTTP \(httpResponse.statusCode))"
                        self.isLoading = false
                        return
                    }
                }
                
                let calendarResponse = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
                
                await MainActor.run {
                    self.events = calendarResponse.items ?? []
                    self.isLoading = false
                    self.error = nil
                    print("✅ Fetched \(self.events.count) Google Calendar events")
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to fetch events: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Failed to fetch Google Calendar events: \(error)")
                }
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
    let colorId: String? // Added for color mapping
    
    var eventIdentifier: String { id }
    var eventTitle: String? { summary }
    var eventStartDate: Date? { start?.dateValue }
    var eventEndDate: Date? { end?.dateValue }
    
    var eventColor: Color {
        // Map Google Calendar colorId to actual Color
        guard let colorId = colorId else { return .blue } // Default to blue if no color
        
        switch colorId {
        case "1": return Color(hex: "#7986cb") // Lavender
        case "2": return Color(hex: "#33b679") // Sage
        case "3": return Color(hex: "#8e24aa") // Grape
        case "4": return Color(hex: "#e67c73") // Flamingo
        case "5": return Color(hex: "#f6c026") // Banana
        case "6": return Color(hex: "#f5511d") // Tangerine
        case "7": return Color(hex: "#039be5") // Peacock
        case "8": return Color(hex: "#616161") // Graphite
        case "9": return Color(hex: "#3f51b5") // Blueberry
        case "10": return Color(hex: "#0b8043") // Basil
        case "11": return Color(hex: "#d60000") // Tomato
        default: return .blue // Fallback
        }
    }
    
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
