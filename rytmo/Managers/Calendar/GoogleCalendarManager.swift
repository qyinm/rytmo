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
    @Published var needsScopeUpgrade: Bool = false
    @AppStorage("calendar_event_range_hours") private var eventRangeHours: Int = 24
    
    private static let legacyReadonlyScope = "https://www.googleapis.com/auth/calendar.readonly"
    
    private var fetchTask: Task<Void, Never>?
    private var syncTimer: Timer?
    private var lastFetchCenterDate: Date = Date()
    private let eventsCacheFileName = "google_events_cache_v3.json"
    private let calendarsCacheFileName = "google_calendars_cache.json"
    
    /// Fetch range: 3 months before and after current date (6 months total)
    private let fetchMonthsBeforeAfter = 3
    /// Background sync interval in seconds (5 minutes)
    private let syncInterval: TimeInterval = 300
    /// Maximum number of events to cache (prevents memory issues for busy users)
    private let maxCachedEvents = 5000
    
    private init() {
        loadCalendarsFromCache()
        loadEventsFromCache()
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncIfNeeded()
            }
        }
    }
    
    private func startPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncInBackground()
            }
        }
    }
    
    private func syncIfNeeded() {
        guard isAuthorized else { return }
        syncInBackground()
    }
    
    private func syncInBackground() {
        guard isAuthorized, fetchTask == nil else { return }
        fetchTask = Task {
            await fetchAllEventsAsync(centerDate: lastFetchCenterDate)
            fetchTask = nil
        }
    }
    
    // MARK: - Caching
    
    private func getCacheURL(fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private func saveEventsToCache(_ events: [GoogleCalendarEvent]) {
        guard let url = getCacheURL(fileName: eventsCacheFileName) else { return }
        
        let eventsToCache: [GoogleCalendarEvent]
        if events.count > maxCachedEvents {
            let sorted = events.sorted { ($0.eventStartDate ?? .distantPast) > ($1.eventStartDate ?? .distantPast) }
            eventsToCache = Array(sorted.prefix(maxCachedEvents))
            print("⚠️ Cache trimmed: \(events.count) → \(maxCachedEvents) events")
        } else {
            eventsToCache = events
        }
        
        Task.detached(priority: .background) { [eventsToCache] in
            do {
                let data = try JSONEncoder().encode(eventsToCache)
                try data.write(to: url)
            } catch {
                print("❌ Failed to save Google Calendar cache: \(error)")
            }
        }
    }
    
    private func loadEventsFromCache() {
        guard let url = getCacheURL(fileName: eventsCacheFileName),
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
    
    private func saveCalendarsToCache(_ calendars: [CalendarInfo]) {
        guard let url = getCacheURL(fileName: calendarsCacheFileName) else { return }
        
        Task.detached(priority: .background) {
            do {
                let cacheable = calendars.map { CacheableCalendarInfo(from: $0) }
                let data = try JSONEncoder().encode(cacheable)
                try data.write(to: url)
            } catch {
                print("❌ Failed to save calendars cache: \(error)")
            }
        }
    }
    
    private func loadCalendarsFromCache() {
        guard let url = getCacheURL(fileName: calendarsCacheFileName),
              FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let cached = try JSONDecoder().decode([CacheableCalendarInfo].self, from: data)
            self.availableCalendars = cached.map { $0.toCalendarInfo() }
            print("✅ Loaded \(cached.count) cached Google calendars")
        } catch {
            print("❌ Failed to load calendars cache: \(error)")
        }
    }
    
    // MARK: - Permission Check
    
    func checkPermission() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            let grantedScopes = user.grantedScopes ?? []
            let hasFullAccess = grantedScopes.contains(GoogleCalendarAPI.scope)
            let hasLegacyReadonly = grantedScopes.contains(Self.legacyReadonlyScope)
            
            self.isAuthorized = hasFullAccess
            self.needsScopeUpgrade = !hasFullAccess && hasLegacyReadonly
            
            if self.needsScopeUpgrade {
                self.error = "Calendar permissions need to be updated. Please reconnect to enable event creation."
            }
            
            if self.isAuthorized {
                Task {
                    async let calendarsTask: () = fetchCalendarListAsync()
                    async let eventsTask: () = fetchAllEventsAsync(centerDate: Date())
                    _ = await (calendarsTask, eventsTask)
                    startPeriodicSync()
                }
            }
        } else {
            self.isAuthorized = false
            self.needsScopeUpgrade = false
        }
    }
    
    func requestScopeUpgrade() async {
        guard let window = NSApplication.shared.windows.first,
              let user = GIDSignIn.sharedInstance.currentUser else {
            self.error = "Cannot upgrade permissions. Please sign in again."
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        do {
            let result = try await user.addScopes([GoogleCalendarAPI.scope], presenting: window)
            
            let hasFullAccess = result.user.grantedScopes?.contains(GoogleCalendarAPI.scope) ?? false
            self.isAuthorized = hasFullAccess
            self.needsScopeUpgrade = !hasFullAccess
            
            if hasFullAccess {
                print("✅ Google Calendar scope upgraded successfully")
                fetchEvents(date: Date())
                fetchCalendarList()
            } else {
                self.error = "Permission upgrade was not granted"
            }
        } catch let error as NSError {
            if error.domain == GoogleCalendarAPI.signInErrorDomain && error.code == GoogleCalendarAPI.cancelledErrorCode {
                print("ℹ️ Scope upgrade cancelled")
            } else {
                self.error = "Failed to upgrade permissions: \(error.localizedDescription)"
                print("❌ Scope upgrade failed: \(error.localizedDescription)")
            }
        }
        
        self.isLoading = false
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
        self.needsScopeUpgrade = false
        self.events = []
        self.error = nil
        print("ℹ️ Google Calendar disconnected")
    }
    
    // MARK: - Fetch Calendars List
    
    func fetchCalendarList() {
        guard isAuthorized else { return }
        
        Task {
            await fetchCalendarListAsync()
        }
    }
    
    private func fetchCalendarListAsync() async {
        guard isAuthorized else { return }
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
                    hexColorString: item.backgroundColor,
                    sourceTitle: "Google (\(user.profile?.email ?? "Account"))",
                    type: .google
                )
            }
            
            self.availableCalendars = calendarInfos
            saveCalendarsToCache(calendarInfos)
            print("✅ Fetched \(calendarInfos.count) Google calendars")
        } catch {
            print("❌ Failed to fetch Google calendar list: \(error)")
        }
    }
    
    // MARK: - Fetch Events
    
    /// Fetch events for a specific date range (centered on the date)
    func fetchEvents(date: Date) {
        guard isAuthorized else {
            print("⚠️ Google Calendar not authorized, skipping fetch")
            return
        }
        
        // Cancel existing task to avoid race conditions and prioritize the new date
        fetchTask?.cancel()
        lastFetchCenterDate = date
        
        fetchTask = Task {
            await fetchAllEventsAsync(centerDate: date)
            fetchTask = nil
        }
    }
    
    /// Fetch 6 months of events (3 months before and after centerDate)
    private func fetchAllEventsAsync(centerDate: Date) async {
        guard isAuthorized else { return }
        
        self.isLoading = true
        self.error = nil
        
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
        let calendar = Calendar.current
        
        // Calculate 6-month range based on centerDate
        guard let startDate = calendar.date(byAdding: .month, value: -fetchMonthsBeforeAfter, to: centerDate),
              let endDate = calendar.date(byAdding: .month, value: fetchMonthsBeforeAfter, to: centerDate) else {
            self.isLoading = false
            return
        }
        
        let isoFormatter = ISO8601DateFormatter()
        let timeMin = isoFormatter.string(from: startDate)
        let timeMax = isoFormatter.string(from: endDate)
        
        let calendarsToFetch = availableCalendars.isEmpty ? [CalendarInfo(id: "primary", title: "Primary", color: .blue, sourceTitle: "", type: .google)] : availableCalendars
        
        // Fetch all calendars in parallel
        let allEvents = await withTaskGroup(of: [GoogleCalendarEvent].self) { group in
            for cal in calendarsToFetch {
                group.addTask {
                    await self.fetchEventsForCalendar(
                        cal: cal,
                        accessToken: accessToken,
                        timeMin: timeMin,
                        timeMax: timeMax
                    )
                }
            }
            
            var results: [GoogleCalendarEvent] = []
            for await events in group {
                results.append(contentsOf: events)
            }
            return results
        }
        
        self.events = allEvents
        self.saveEventsToCache(allEvents)
        self.isLoading = false
        self.error = nil
        print("✅ Fetched \(allEvents.count) Google events for 6 months from \(calendarsToFetch.count) calendars")
    }
    
    private func fetchEventsForCalendar(cal: CalendarInfo, accessToken: String, timeMin: String, timeMax: String) async -> [GoogleCalendarEvent] {
        let urlString = GoogleCalendarAPI.eventsURL(calendarId: cal.id)
        var allEvents: [GoogleCalendarEvent] = []
        var pageToken: String? = nil
        
        // Paginate through all results (Google API max 2500 per request)
        repeat {
            guard var components = URLComponents(string: urlString) else { return allEvents }
            components.queryItems = [
                URLQueryItem(name: "timeMin", value: timeMin),
                URLQueryItem(name: "timeMax", value: timeMax),
                URLQueryItem(name: "singleEvents", value: "true"),
                URLQueryItem(name: "orderBy", value: "startTime"),
                URLQueryItem(name: "maxResults", value: "2500")
            ]
            if let token = pageToken {
                components.queryItems?.append(URLQueryItem(name: "pageToken", value: token))
            }
            
            guard let url = components.url else { return allEvents }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 {
                        await MainActor.run {
                            self.isAuthorized = false
                            self.error = "Session expired. Please reconnect Google Calendar."
                        }
                        return allEvents
                    } else if httpResponse.statusCode != 200 {
                        return allEvents
                    }
                }
                
                let calendarResponse = try JSONDecoder().decode(GoogleCalendarPaginatedResponse.self, from: data)
                var calEvents = calendarResponse.items ?? []
                
                for i in calEvents.indices {
                    calEvents[i].storedCalendarId = cal.id
                    calEvents[i].storedCalendarColorHex = cal.hexColorString ?? "#4285F4"
                }
                
                allEvents.append(contentsOf: calEvents)
                pageToken = calendarResponse.nextPageToken
            } catch {
                print("⚠️ Failed to fetch events from calendar \(cal.title): \(error)")
                return allEvents
            }
        } while pageToken != nil
        
        return allEvents
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
            // Google Calendar API uses exclusive end date for all-day events
            let exclusiveEndDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
            eventBody["end"] = ["date": dateFormatter.string(from: exclusiveEndDate)]
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
            // Google Calendar API uses exclusive end date for all-day events
            let exclusiveEndDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
            eventBody["end"] = ["date": dateFormatter.string(from: exclusiveEndDate)]
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

struct GoogleCalendarPaginatedResponse: Codable {
    let items: [GoogleCalendarEvent]?
    let nextPageToken: String?
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
    
    // Calendar Info is set after decoding and persisted
    var storedCalendarId: String?
    var storedCalendarColorHex: String?
    
    // Legacy property for runtime backward compatibility if needed, but we rely on hex now
    var storedCalendarColor: Color? {
        if let hex = storedCalendarColorHex {
            return Color(hex: hex)
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, summary, start, end, htmlLink, colorId, location, description
        case storedCalendarId, storedCalendarColorHex
    }
    
    var eventIdentifier: String { id }
    var eventTitle: String? { summary }
    var eventStartDate: Date? { start?.dateValue }
    
    // For all-day events, Google returns exclusive end date (next day)
    // We convert it to inclusive end date (same day) for app display
    var eventEndDate: Date? {
        guard let date = end?.dateValue else { return nil }
        
        if isAllDay {
            return Calendar.current.date(byAdding: .day, value: -1, to: date)
        }
        
        return date
    }
    
    var eventColor: Color {
        if let colorId = colorId {
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
            default: break
            }
        }
        
        return storedCalendarColor ?? .blue
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

// MARK: - Cacheable Calendar Info

struct CacheableCalendarInfo: Codable {
    let id: String
    let title: String
    let hexColorString: String?
    let sourceTitle: String
    
    init(from info: CalendarInfo) {
        self.id = info.id
        self.title = info.title
        self.hexColorString = info.hexColorString
        self.sourceTitle = info.sourceTitle
    }
    
    func toCalendarInfo() -> CalendarInfo {
        CalendarInfo(
            id: id,
            title: title,
            color: Color(hex: hexColorString ?? "#4285F4"),
            hexColorString: hexColorString,
            sourceTitle: sourceTitle,
            type: .google
        )
    }
}
