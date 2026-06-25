import Foundation
import GoogleSignIn
import Combine
import SwiftUI
import FirebaseCore
import EventKit

// MARK: - Constants

private enum GoogleCalendarAPI {
    static let scope = "https://www.googleapis.com/auth/calendar"
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
    /// True when the user can read Google Calendar events (full or read-only scope).
    @Published var isAuthorized: Bool = false
    /// True when the user can create, update, or delete Google Calendar events.
    @Published var canWriteEvents: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    /// True when the user granted read-only access and still needs the full calendar scope to edit.
    @Published var needsScopeUpgrade: Bool = false
    @AppStorage("calendar_event_range_hours") private var eventRangeHours: Int = 24
    
    private static let legacyReadonlyScope = "https://www.googleapis.com/auth/calendar.readonly"
    
    private var fetchTask: Task<Void, Never>?
    private var fetchGeneration = 0
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
    private static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    private static let eventISOFormatter = ISO8601DateFormatter()
    
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
        fetchGeneration += 1
        let generation = fetchGeneration
        fetchTask = Task {
            await fetchAllEventsAsync(centerDate: lastFetchCenterDate, generation: generation)
            if !Task.isCancelled && fetchGeneration == generation {
                fetchTask = nil
            }
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
        let cacheable = calendars.map { CacheableCalendarInfo(from: $0) }
        
        Task.detached(priority: .background) { [cacheable] in
            do {
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
            let hasReadonlyAccess = grantedScopes.contains(Self.legacyReadonlyScope)
            let hasReadAccess = hasFullAccess || hasReadonlyAccess

            self.isAuthorized = hasReadAccess
            self.canWriteEvents = hasFullAccess
            self.needsScopeUpgrade = hasReadAccess && !hasFullAccess

            if self.needsScopeUpgrade {
                self.error = nil
            }

            if self.isAuthorized {
                Task {
                    async let calendarsTask: () = fetchCalendarListAsync()
                    await calendarsTask
                    fetchEvents(date: Date())
                    startPeriodicSync()
                }
            }
        } else {
            disconnect()
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
            
            let grantedScopes = result.user.grantedScopes ?? []
            let hasFullAccess = grantedScopes.contains(GoogleCalendarAPI.scope)
            let hasReadonlyAccess = grantedScopes.contains(Self.legacyReadonlyScope)
            let hasReadAccess = hasFullAccess || hasReadonlyAccess

            self.isAuthorized = hasReadAccess
            self.canWriteEvents = hasFullAccess
            self.needsScopeUpgrade = hasReadAccess && !hasFullAccess

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
            markUnauthorized("Failed to refresh token: \(error.localizedDescription)")
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
            
            let grantedScopes = result.user.grantedScopes ?? []
            let hasFullAccess = grantedScopes.contains(GoogleCalendarAPI.scope)
            let hasReadonlyAccess = grantedScopes.contains(Self.legacyReadonlyScope)
            let hasReadAccess = hasFullAccess || hasReadonlyAccess

            self.isAuthorized = hasReadAccess
            self.canWriteEvents = hasFullAccess
            self.needsScopeUpgrade = hasReadAccess && !hasFullAccess

            if self.isAuthorized {
                print("✅ Google Calendar access granted (\(hasFullAccess ? "read/write" : "read-only"))")
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
        fetchGeneration += 1
        fetchTask?.cancel()
        fetchTask = nil
        syncTimer?.invalidate()
        syncTimer = nil
        isLoading = false
        isAuthorized = false
        canWriteEvents = false
        needsScopeUpgrade = false
        events = []
        availableCalendars = []
        error = nil
        clearCache()
        print("ℹ️ Google Calendar disconnected")
    }

    private func markUnauthorized(_ message: String = "Session expired. Please reconnect Google Calendar.") {
        fetchGeneration += 1
        fetchTask?.cancel()
        fetchTask = nil
        syncTimer?.invalidate()
        syncTimer = nil
        isLoading = false
        isAuthorized = false
        canWriteEvents = false
        needsScopeUpgrade = false
        error = message
    }

    private func clearCache() {
        for fileName in [eventsCacheFileName, calendarsCacheFileName] {
            guard let url = getCacheURL(fileName: fileName),
                  FileManager.default.fileExists(atPath: url.path) else { continue }

            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("❌ Failed to clear Google Calendar cache \(fileName): \(error)")
            }
        }
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

            guard isAuthorized else { return }
            
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
        fetchGeneration += 1
        let generation = fetchGeneration
        lastFetchCenterDate = date
        
        fetchTask = Task {
            await fetchAllEventsAsync(centerDate: date, generation: generation)
            if !Task.isCancelled && fetchGeneration == generation {
                fetchTask = nil
            }
        }
    }
    
    /// Fetch 6 months of events (3 months before and after centerDate)
    private func fetchAllEventsAsync(centerDate: Date, generation: Int) async {
        guard isAuthorized, fetchGeneration == generation, !Task.isCancelled else { return }
        
        self.isLoading = true
        self.error = nil
        
        guard await refreshTokenIfNeeded() else {
            if fetchGeneration == generation {
                self.isLoading = false
            }
            return
        }

        guard isAuthorized, fetchGeneration == generation, !Task.isCancelled else { return }
        
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            if fetchGeneration == generation {
                markUnauthorized("Google user not found. Please reconnect Google Calendar.")
            }
            return
        }
        
        let accessToken = user.accessToken.tokenString
        let calendar = Calendar.current
        
        // Calculate 6-month range based on centerDate
        guard let startDate = calendar.date(byAdding: .month, value: -fetchMonthsBeforeAfter, to: centerDate),
              let endDate = calendar.date(byAdding: .month, value: fetchMonthsBeforeAfter, to: centerDate) else {
            if fetchGeneration == generation {
                self.isLoading = false
            }
            return
        }
        
        let timeMin = Self.eventISOFormatter.string(from: startDate)
        let timeMax = Self.eventISOFormatter.string(from: endDate)
        
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
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                results.append(contentsOf: events)
            }
            return results
        }

        guard isAuthorized, fetchGeneration == generation, !Task.isCancelled else { return }
        
        let normalizedEvents = normalizeEvents(allEvents)
        if !matchesCurrentEvents(normalizedEvents) {
            self.events = normalizedEvents
            self.saveEventsToCache(normalizedEvents)
        }
        self.isLoading = false
        self.error = nil
        print("✅ Fetched \(normalizedEvents.count) Google events for 6 months from \(calendarsToFetch.count) calendars")
    }

    private func normalizeEvents(_ events: [GoogleCalendarEvent]) -> [GoogleCalendarEvent] {
        var seenKeys = Set<String>()
        var deduped: [GoogleCalendarEvent] = []
        deduped.reserveCapacity(events.count)

        for event in events {
            let key = "\(event.calendarId ?? ""):\(event.eventIdentifier)"
            if seenKeys.insert(key).inserted {
                deduped.append(event)
            }
        }

        deduped.sort {
            let lhsStart = $0.eventStartDate ?? .distantPast
            let rhsStart = $1.eventStartDate ?? .distantPast
            if lhsStart != rhsStart {
                return lhsStart < rhsStart
            }
            return $0.eventIdentifier < $1.eventIdentifier
        }

        return deduped
    }

    private func matchesCurrentEvents(_ candidate: [GoogleCalendarEvent]) -> Bool {
        guard events.count == candidate.count else { return false }
        return zip(events, candidate).allSatisfy { lhs, rhs in
            lhs.eventIdentifier == rhs.eventIdentifier &&
            lhs.eventTitle == rhs.eventTitle &&
            lhs.eventStartDate == rhs.eventStartDate &&
            lhs.eventEndDate == rhs.eventEndDate &&
            lhs.isAllDay == rhs.isAllDay &&
            lhs.eventLocation == rhs.eventLocation &&
            lhs.eventNotes == rhs.eventNotes &&
            lhs.calendarId == rhs.calendarId
        }
    }
    
    private func fetchEventsForCalendar(cal: CalendarInfo, accessToken: String, timeMin: String, timeMax: String) async -> [GoogleCalendarEvent] {
        let urlString = GoogleCalendarAPI.eventsURL(calendarId: cal.id)
        var allEvents: [GoogleCalendarEvent] = []
        var pageToken: String? = nil
        
        // Paginate through all results (Google API max 2500 per request)
        repeat {
            guard !Task.isCancelled else { return allEvents }
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
                        markUnauthorized()
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

    private func removeCachedEvent(eventId: String) {
        let filteredEvents = events.filter { $0.eventIdentifier != eventId }
        guard filteredEvents.count != events.count else { return }
        events = filteredEvents
        saveEventsToCache(filteredEvents)
    }

    private func upsertCachedEvent(
        _ event: GoogleCalendarEvent,
        replacing originalEventId: String? = nil
    ) {
        let idsToReplace = Set([originalEventId, event.eventIdentifier].compactMap { $0 })
        var filteredEvents = events.filter { !idsToReplace.contains($0.eventIdentifier) }
        filteredEvents.append(event)
        filteredEvents.sort {
            let lhsStart = $0.eventStartDate ?? .distantPast
            let rhsStart = $1.eventStartDate ?? .distantPast
            if lhsStart != rhsStart {
                return lhsStart < rhsStart
            }
            return $0.eventIdentifier < $1.eventIdentifier
        }
        events = filteredEvents
        saveEventsToCache(filteredEvents)
    }

    private func decorateEvent(_ event: GoogleCalendarEvent, calendarId: String) -> GoogleCalendarEvent {
        var decoratedEvent = event
        decoratedEvent.storedCalendarId = calendarId
        decoratedEvent.storedCalendarColorHex = availableCalendars.first(where: { $0.id == calendarId })?.hexColorString ?? "#4285F4"
        return decoratedEvent
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
        guard canWriteEvents else {
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
        var eventBody: [String: Any] = [
            "summary": title
        ]

        if isAllDay {
            eventBody["start"] = ["date": Self.eventDateFormatter.string(from: startDate)]
            // Google Calendar API uses exclusive end date for all-day events
            let exclusiveEndDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
            eventBody["end"] = ["date": Self.eventDateFormatter.string(from: exclusiveEndDate)]
        } else {
            eventBody["start"] = ["dateTime": Self.eventISOFormatter.string(from: startDate)]
            eventBody["end"] = ["dateTime": Self.eventISOFormatter.string(from: endDate)]
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
            let createdEvent = try JSONDecoder().decode(GoogleCalendarEvent.self, from: data)
            upsertCachedEvent(decorateEvent(createdEvent, calendarId: calendarId))
        case 401:
            markUnauthorized()
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
        targetCalendarId: String? = nil,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String?,
        notes: String?
    ) async throws {
        guard canWriteEvents else {
            throw GoogleCalendarError.notAuthorized
        }

        guard await refreshTokenIfNeeded(),
              let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleCalendarError.tokenRefreshFailed
        }

        let accessToken = user.accessToken.tokenString
        let targetCalendarId = targetCalendarId ?? calendarId
        let eventIdToUpdate: String

        if targetCalendarId != calendarId {
            eventIdToUpdate = try await moveEvent(
                eventId: eventId,
                from: calendarId,
                to: targetCalendarId,
                accessToken: accessToken
            )
        } else {
            eventIdToUpdate = eventId
        }

        let encodedEventId = eventIdToUpdate.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? eventIdToUpdate
        let urlString = "\(GoogleCalendarAPI.eventsURL(calendarId: targetCalendarId))/\(encodedEventId)"

        guard let url = URL(string: urlString) else {
            throw GoogleCalendarError.invalidURL
        }

        var eventBody: [String: Any] = ["summary": title]

        if isAllDay {
            eventBody["start"] = ["date": Self.eventDateFormatter.string(from: startDate)]
            // Google Calendar API uses exclusive end date for all-day events
            let exclusiveEndDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
            eventBody["end"] = ["date": Self.eventDateFormatter.string(from: exclusiveEndDate)]
        } else {
            eventBody["start"] = ["dateTime": Self.eventISOFormatter.string(from: startDate)]
            eventBody["end"] = ["dateTime": Self.eventISOFormatter.string(from: endDate)]
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
            let updatedEvent = try JSONDecoder().decode(GoogleCalendarEvent.self, from: data)
            upsertCachedEvent(
                decorateEvent(updatedEvent, calendarId: targetCalendarId),
                replacing: eventId
            )
        case 401:
            markUnauthorized()
            throw GoogleCalendarError.unauthorized
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleCalendarError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }

    private func moveEvent(
        eventId: String,
        from sourceCalendarId: String,
        to targetCalendarId: String,
        accessToken: String
    ) async throws -> String {
        let encodedEventId = eventId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? eventId
        let urlString = "\(GoogleCalendarAPI.eventsURL(calendarId: sourceCalendarId))/\(encodedEventId)/move"

        guard var components = URLComponents(string: urlString) else {
            throw GoogleCalendarError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "destination", value: targetCalendarId)
        ]

        guard let url = components.url else {
            throw GoogleCalendarError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            print("✅ Google Calendar event moved successfully")
            let movedEvent = try JSONDecoder().decode(GoogleCalendarEvent.self, from: data)
            upsertCachedEvent(
                decorateEvent(movedEvent, calendarId: targetCalendarId),
                replacing: eventId
            )
            return movedEvent.eventIdentifier
        case 401:
            markUnauthorized()
            throw GoogleCalendarError.unauthorized
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleCalendarError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    // MARK: - Delete Event
    
    /// Deletes an event from Google Calendar
    func deleteEvent(eventId: String, calendarId: String) async throws {
        guard canWriteEvents else {
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
            removeCachedEvent(eventId: eventId)
        case 401:
            markUnauthorized()
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
            return "Google Calendar write access is not granted. Enable calendar editing in Settings."
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
