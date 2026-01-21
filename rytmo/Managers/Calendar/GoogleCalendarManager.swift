import Foundation
import GoogleSignIn
import Combine
import SwiftUI
import FirebaseCore
import EventKit

// MARK: - Constants

private enum GoogleCalendarAPI {
    static let scope = "https://www.googleapis.com/auth/calendar"
    static let baseURL = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
    static let calendarListURL = "https://www.googleapis.com/calendar/v3/users/me/calendarList"
    static func eventsURL(calendarId: String) -> String {
        let encodedId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarId
        return "https://www.googleapis.com/calendar/v3/calendars/\(encodedId)/events"
    }
    static let signInErrorDomain = "com.google.GIDSignIn"
    static let cancelledErrorCode = -5
}

@MainActor
class GoogleCalendarManager: ObservableObject {
    static let shared = GoogleCalendarManager()
    
    @Published var events: [GoogleCalendarEvent] = []
    @Published var availableCalendars: [CalendarInfo] = []
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @AppStorage("calendar_event_range_hours") private var eventRangeHours: Int = 24
    
    private var fetchTask: Task<Void, Never>?
    private let cacheFileName = "google_events_cache.json"
    
    private init() {
        loadEventsFromCache()
    }
    
    // MARK: - Caching
    
    private func getCacheURL() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent(cacheFileName)
    }
    
    private func saveEventsToCache(_ events: [GoogleCalendarEvent]) {
        guard let url = getCacheURL() else { return }
        
        Task.detached(priority: .background) {
            do {
                let data = try JSONEncoder().encode(events)
                try data.write(to: url)
            } catch {
                print("❌ Failed to save Google Calendar cache: \(error)")
            }
        }
    }
    
    private func loadEventsFromCache() {
        guard let url = getCacheURL(),
              FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let cachedEvents = try JSONDecoder().decode([GoogleCalendarEvent].self, from: data)
            self.events = cachedEvents
            print("✅ Loaded \(cachedEvents.count) cached Google events")
        } catch {
            print("❌ Failed to load Google Calendar cache: \(error)")
        }
    }
    
    // MARK: - Permission Check
    
    func checkPermission() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            let grantedScopes = user.grantedScopes ?? []
            self.isAuthorized = grantedScopes.contains(GoogleCalendarAPI.scope)
            if self.isAuthorized {
                // Automatically fetch events when permission is confirmed
                fetchEvents(date: Date())
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
                fetchEvents(date: Date())
                fetchCalendarList()
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
    
    // MARK: - Fetch Calendars List
    
    func fetchCalendarList() {
        guard isAuthorized else { return }
        
        Task {
            guard await refreshTokenIfNeeded(),
                  let user = GIDSignIn.sharedInstance.currentUser else { return }
            
            let accessToken = user.accessToken.tokenString
            guard let url = URL(string: GoogleCalendarAPI.calendarListURL) else { return }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(GoogleCalendarListResource.self, from: data)
                
                let calendarInfos = (response.items ?? []).map { item in
                    CalendarInfo(
                        id: item.id,
                        title: item.summary ?? "Untitled",
                        color: Color(hex: item.backgroundColor ?? "#4285F4"),
                        sourceTitle: "Google (\(user.profile?.email ?? "Account"))",
                        type: .google
                    )
                }
                
                await MainActor.run {
                    self.availableCalendars = calendarInfos
                }
            } catch {
                print("❌ Failed to fetch Google calendar list: \(error)")
            }
        }
    }
    
    // MARK: - Fetch Events
    
    func fetchEvents(date: Date) {
        guard isAuthorized else {
            print("⚠️ Google Calendar not authorized, skipping fetch")
            return
        }
        
        fetchTask?.cancel()
        
        self.isLoading = true
        self.error = nil
        
        fetchTask = Task {
            // Refresh token before making API call
            guard await refreshTokenIfNeeded() else {
                if !Task.isCancelled { self.isLoading = false }
                return
            }
            
            guard let user = GIDSignIn.sharedInstance.currentUser else {
                if !Task.isCancelled {
                    self.isLoading = false
                    self.error = "User not found"
                }
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            let calendar = Calendar.current
            guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
                if !Task.isCancelled { self.isLoading = false }
                return
            }
            
            let monthDays = CalendarUtils.generateDaysInMonth(for: date)
            let start = monthDays.first ?? monthInterval.start
            let end = calendar.date(byAdding: .day, value: 1, to: monthDays.last ?? monthInterval.end) ?? monthInterval.end
            
            let isoFormatter = ISO8601DateFormatter()
            let timeMin = isoFormatter.string(from: start)
            let timeMax = isoFormatter.string(from: end)
            
            // Fetch events from all available calendars
            var allEvents: [GoogleCalendarEvent] = []
            let calendarsToFetch = availableCalendars.isEmpty ? [CalendarInfo(id: "primary", title: "Primary", color: .blue, sourceTitle: "", type: .google)] : availableCalendars
            
            for cal in calendarsToFetch {
                if Task.isCancelled { return }
                
                let urlString = GoogleCalendarAPI.eventsURL(calendarId: cal.id)
                
                guard var components = URLComponents(string: urlString) else { continue }
                components.queryItems = [
                    URLQueryItem(name: "timeMin", value: timeMin),
                    URLQueryItem(name: "timeMax", value: timeMax),
                    URLQueryItem(name: "singleEvents", value: "true"),
                    URLQueryItem(name: "orderBy", value: "startTime"),
                    URLQueryItem(name: "maxResults", value: "250")
                ]
                
                guard let url = components.url else { continue }
                
                var request = URLRequest(url: url)
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 401 {
                            await MainActor.run {
                                self.isAuthorized = false
                                self.error = "Session expired. Please reconnect Google Calendar."
                                self.isLoading = false
                            }
                            return
                        } else if httpResponse.statusCode != 200 {
                            continue // Skip this calendar if error
                        }
                    }
                    
                    let calendarResponse = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
                    var calEvents = calendarResponse.items ?? []
                    
                    // Set the calendarId for each event
                    for i in calEvents.indices {
                        calEvents[i].storedCalendarId = cal.id
                    }
                    
                    allEvents.append(contentsOf: calEvents)
                } catch {
                    print("⚠️ Failed to fetch events from calendar \(cal.title): \(error)")
                    continue
                }
            }
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                self.events = allEvents
                self.saveEventsToCache(allEvents)
                self.isLoading = false
                self.error = nil
                print("✅ Fetched \(self.events.count) Google Calendar events from \(calendarsToFetch.count) calendars")
            }
        }
    }
    
    // MARK: - Create Event
    
    /// Creates a new event in the specified Google Calendar
    /// - Parameters:
    ///   - calendarId: The ID of the calendar to add the event to
    ///   - title: Event title
    ///   - startDate: Start date/time
    ///   - endDate: End date/time
    ///   - isAllDay: Whether this is an all-day event
    ///   - location: Optional location string
    ///   - notes: Optional description/notes
    func createEvent(
        calendarId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String?,
        notes: String?
    ) async throws {
        guard isAuthorized else {
            throw GoogleCalendarError.notAuthorized
        }
        
        guard await refreshTokenIfNeeded(),
              let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleCalendarError.tokenRefreshFailed
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = GoogleCalendarAPI.eventsURL(calendarId: calendarId)
        
        guard let url = URL(string: urlString) else {
            throw GoogleCalendarError.invalidURL
        }
        
        // Build request body
        let isoFormatter = ISO8601DateFormatter()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var eventBody: [String: Any] = [
            "summary": title
        ]
        
        if isAllDay {
            eventBody["start"] = ["date": dateFormatter.string(from: startDate)]
            eventBody["end"] = ["date": dateFormatter.string(from: endDate)]
        } else {
            eventBody["start"] = ["dateTime": isoFormatter.string(from: startDate)]
            eventBody["end"] = ["dateTime": isoFormatter.string(from: endDate)]
        }
        
        if let location = location, !location.isEmpty {
            eventBody["location"] = location
        }
        
        if let notes = notes, !notes.isEmpty {
            eventBody["description"] = notes
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: eventBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200, 201:
            print("✅ Google Calendar event created successfully")
            // Refresh events to show the new event
            fetchEvents(date: startDate)
        case 401:
            self.isAuthorized = false
            throw GoogleCalendarError.unauthorized
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Failed to create event: HTTP \(httpResponse.statusCode) - \(errorMessage)")
            throw GoogleCalendarError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    // MARK: - Update Event
    
    /// Updates an existing event in Google Calendar
    func updateEvent(
        eventId: String,
        calendarId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String?,
        notes: String?
    ) async throws {
        guard isAuthorized else {
            throw GoogleCalendarError.notAuthorized
        }
        
        guard await refreshTokenIfNeeded(),
              let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleCalendarError.tokenRefreshFailed
        }
        
        let accessToken = user.accessToken.tokenString
        let encodedEventId = eventId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? eventId
        let urlString = "\(GoogleCalendarAPI.eventsURL(calendarId: calendarId))/\(encodedEventId)"
        
        guard let url = URL(string: urlString) else {
            throw GoogleCalendarError.invalidURL
        }
        
        let isoFormatter = ISO8601DateFormatter()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var eventBody: [String: Any] = ["summary": title]
        
        if isAllDay {
            eventBody["start"] = ["date": dateFormatter.string(from: startDate)]
            eventBody["end"] = ["date": dateFormatter.string(from: endDate)]
        } else {
            eventBody["start"] = ["dateTime": isoFormatter.string(from: startDate)]
            eventBody["end"] = ["dateTime": isoFormatter.string(from: endDate)]
        }
        
        if let location = location, !location.isEmpty {
            eventBody["location"] = location
        }
        
        if let notes = notes, !notes.isEmpty {
            eventBody["description"] = notes
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: eventBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            print("✅ Google Calendar event updated successfully")
            fetchEvents(date: startDate)
        case 401:
            self.isAuthorized = false
            throw GoogleCalendarError.unauthorized
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleCalendarError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    // MARK: - Delete Event
    
    /// Deletes an event from Google Calendar
    func deleteEvent(eventId: String, calendarId: String) async throws {
        guard isAuthorized else {
            throw GoogleCalendarError.notAuthorized
        }
        
        guard await refreshTokenIfNeeded(),
              let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleCalendarError.tokenRefreshFailed
        }
        
        let accessToken = user.accessToken.tokenString
        let encodedEventId = eventId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? eventId
        let urlString = "\(GoogleCalendarAPI.eventsURL(calendarId: calendarId))/\(encodedEventId)"
        
        guard let url = URL(string: urlString) else {
            throw GoogleCalendarError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 204, 200:
            print("✅ Google Calendar event deleted successfully")
            fetchEvents(date: Date())
        case 401:
            self.isAuthorized = false
            throw GoogleCalendarError.unauthorized
        default:
            throw GoogleCalendarError.apiError(statusCode: httpResponse.statusCode, message: "Delete failed")
        }
    }
}

// MARK: - Google Calendar Errors

enum GoogleCalendarError: LocalizedError {
    case notAuthorized
    case tokenRefreshFailed
    case invalidURL
    case invalidResponse
    case unauthorized
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Google Calendar is not authorized. Please sign in."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token."
        case .invalidURL:
            return "Invalid calendar URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .unauthorized:
            return "Session expired. Please reconnect Google Calendar."
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}

// MARK: - Models for Google Calendar API

struct GoogleCalendarListResource: Codable {
    let items: [GoogleCalendarListItem]?
}

struct GoogleCalendarListItem: Codable {
    let id: String
    let summary: String?
    let backgroundColor: String?
}

struct GoogleCalendarListResponse: Codable {
    let items: [GoogleCalendarEvent]?
}

struct GoogleCalendarEvent: Codable, CalendarEventProtocol {
    let id: String
    let summary: String?
    let start: GoogleCalendarTime?
    let end: GoogleCalendarTime?
    let htmlLink: String?
    let colorId: String?
    let location: String?
    let description: String?
    
    // CalendarId is set after decoding (from API context)
    var storedCalendarId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, summary, start, end, htmlLink, colorId, location, description
    }
    
    var eventIdentifier: String { id }
    var eventTitle: String? { summary }
    var eventStartDate: Date? { start?.dateValue }
    var eventEndDate: Date? { end?.dateValue }
    
    var eventColor: Color {
        guard let colorId = colorId else { return .blue }
        
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
        default: return .blue
        }
    }
    
    var sourceName: String { "Google" }
    
    // Additional properties for edit/delete
    var isAllDay: Bool { start?.date != nil }
    var eventLocation: String? { location }
    var eventNotes: String? { description }
    var calendarId: String? { storedCalendarId }
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
