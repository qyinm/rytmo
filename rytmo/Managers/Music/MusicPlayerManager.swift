//
//  MusicPlayerManager.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI
import SwiftData
import YouTubePlayerKit
import Combine
import AppKit

// MARK: - Noembed Response

struct NoembedResponse: Codable {
    let title: String?
    let thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case title
        case thumbnailUrl = "thumbnail_url"
    }
}

// MARK: - YouTube API Response

struct YouTubePlaylistItemListResponse: Codable {
    let items: [YouTubePlaylistItem]
    let nextPageToken: String?
}

struct YouTubePlaylistItem: Codable {
    let snippet: YouTubePlaylistItemSnippet
}

struct YouTubePlaylistItemSnippet: Codable {
    let title: String
    let resourceId: YouTubeResourceId
    let thumbnails: YouTubeThumbnails?
}

struct YouTubeResourceId: Codable {
    let videoId: String
}

struct YouTubeThumbnails: Codable {
    let defaultThumbnail: YouTubeThumbnail?
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
    let standard: YouTubeThumbnail?
    let maxres: YouTubeThumbnail?
    
    enum CodingKeys: String, CodingKey {
        case defaultThumbnail = "default"
        case medium
        case high
        case standard
        case maxres
    }

    var bestAvailable: URL? {
        if let url = maxres?.url { return URL(string: url) }
        if let url = standard?.url { return URL(string: url) }
        if let url = high?.url { return URL(string: url) }
        if let url = medium?.url { return URL(string: url) }
        if let url = defaultThumbnail?.url { return URL(string: url) }
        return nil
    }
}

struct YouTubeThumbnail: Codable {
    let url: String
}

// MARK: - Music Player Manager

@MainActor
class MusicPlayerManager: ObservableObject {

    // MARK: - Published Properties

    @Published var youTubePlayer: YouTubePlayer
    @Published var currentTrack: MusicTrack?
    @Published var selectedPlaylist: Playlist?
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var playbackTitle: String?

    // MARK: - Private Properties

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var backgroundWindow: NSWindow?

    // MARK: - Initialization

    init() {
        // YouTubePlayer configuration
        let configuration = YouTubePlayer.Configuration(
            fullscreenMode: .system
        )
        self.youTubePlayer = YouTubePlayer(configuration: configuration)

        setupBackgroundPlayer()
        setupPlayerObservation()
    }

    private func setupBackgroundPlayer() {
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isExcludedFromWindowsMenu = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        
        let playerView = YouTubePlayerView(self.youTubePlayer)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            
        let hostingController = NSHostingController(rootView: playerView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        window.contentViewController = hostingController
        
        self.backgroundWindow = window
        
        window.setFrameOrigin(NSPoint(x: -10000, y: -10000))
        window.orderFront(nil)
    }

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    private func setupPlayerObservation() {
        // Observe playback state
        youTubePlayer.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }

                switch state {
                case .playing:
                    self.isPlaying = true

                    // 이벤트 트래킹 - 음악 재생
                    if let track = self.currentTrack {
                        AmplitudeManager.shared.trackMusicPlayed(
                            trackTitle: track.title,
                            playlistName: self.selectedPlaylist?.name
                        )
                    }

                case .paused, .ended, .unstarted, .cued:
                    let wasPlaying = self.isPlaying
                    self.isPlaying = false

                    // 이벤트 트래킹 - 음악 일시정지 (재생 중이었을 때만)
                    if wasPlaying && state == .paused {
                        AmplitudeManager.shared.trackMusicPaused()
                    }

                    if state == .ended {
                        self.playNextTrack()
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Observe playback metadata
        youTubePlayer.playbackMetadataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metadata in
                self?.playbackTitle = metadata.title
            }
            .store(in: &cancellables)
    }

    // MARK: - YouTube URL Parsing

    static func extractVideoId(from urlString: String) -> String? {
        // Pattern 1: youtube.com/watch?v=ID
        // Pattern 2: youtu.be/ID
        // Pattern 3: youtube.com/embed/ID
        // Pattern 4: youtube.com/v/ID

        let patterns = [
            #"(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/v\/)([a-zA-Z0-9_-]{11})"#,
            #"^([a-zA-Z0-9_-]{11})$"# // Direct video ID
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: urlString, options: [], range: NSRange(urlString.startIndex..., in: urlString)),
               let range = Range(match.range(at: 1), in: urlString) {
                return String(urlString[range])
            }
        }

        return nil
    }

    static func extractPlaylistId(from urlString: String) -> String? {
        // Pattern: list=ID
        let pattern = #"(?:list=)([a-zA-Z0-9_-]+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: urlString, options: [], range: NSRange(urlString.startIndex..., in: urlString)),
           let range = Range(match.range(at: 1), in: urlString) {
            return String(urlString[range])
        }
        
        return nil
    }

    // MARK: - Fetch Video Metadata

    func fetchVideoMetadata(videoId: String) async -> (title: String, thumbnailUrl: URL?)? {
        let urlString = "https://noembed.com/embed?url=https://www.youtube.com/watch?v=\(videoId)"

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(NoembedResponse.self, from: data)

            let title = response.title ?? "Unknown Title"
            let thumbnailUrl = response.thumbnailUrl.flatMap { URL(string: $0) }

            return (title, thumbnailUrl)
        } catch {
            print("Failed to fetch metadata: \(error)")
            return nil
        }
    }

    struct YouTubeAPIErrorResponse: Decodable {
        let error: YouTubeAPIErrorDetails
    }

    struct YouTubeAPIErrorDetails: Decodable {
        let code: Int
        let message: String
        let status: String?
    }

    func fetchPlaylistItems(playlistId: String, pageToken: String? = nil) async -> [MusicTrack] {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "YoutubeDataAPIKey") as? String,
              !apiKey.isEmpty, !apiKey.contains("$(") else {
            print("❌ YouTube Data API Key is missing or invalid (check Info.plist and Config.xcconfig)")
            return []
        }

        var urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet,contentDetails&playlistId=\(playlistId)&key=\(apiKey)&maxResults=50"
        if let pageToken = pageToken {
            urlString += "&pageToken=\(pageToken)"
        }
        
        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 YouTube API Status: \(httpResponse.statusCode) for PlaylistID: \(playlistId)")
            }
            
            // Try to decode successful response
            if let listResponse = try? JSONDecoder().decode(YouTubePlaylistItemListResponse.self, from: data) {
                 var tracks = listResponse.items.compactMap { item -> MusicTrack? in
                    let videoId = item.snippet.resourceId.videoId
                    let title = item.snippet.title
                    let thumbnailUrl = item.snippet.thumbnails?.bestAvailable
                    
                    if title == "Private video" || title == "Deleted video" { return nil }
                    
                    return MusicTrack(
                        title: title, 
                        videoId: videoId, 
                        thumbnailUrl: thumbnailUrl, 
                        sortIndex: 0 
                    )
                }
                
                if let nextPageToken = listResponse.nextPageToken {
                    let nextTracks = await fetchPlaylistItems(playlistId: playlistId, pageToken: nextPageToken)
                    tracks.append(contentsOf: nextTracks)
                }
                
                return tracks
            } else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(YouTubeAPIErrorResponse.self, from: data) {
                    print("❌ YouTube API Error: \(errorResponse.error.message) (Code: \(errorResponse.error.code))")
                } else {
                    // Print raw string for debugging
                    let rawString = String(data: data, encoding: .utf8) ?? "Unable to decode data"
                    print("❌ Failed to decode YouTube API response. Raw data: \(rawString)")
                }
                return []
            }
        } catch {
            print("❌ Network or decoding error: \(error)")
            return []
        }
    }

    // MARK: - Playlist Management

    func syncPlaylistWithYouTube(_ playlist: Playlist) async -> (success: Bool, newTracksCount: Int) {
        guard let playlistId = playlist.youtubePlaylistId else {
            print("❌ No YouTube playlist ID found")
            return (false, 0)
        }

        guard let context = modelContext else {
            print("❌ ModelContext not available")
            return (false, 0)
        }

        isLoading = true
        errorMessage = nil

        // Fetch all tracks from YouTube
        let youtubeTracks = await fetchPlaylistItems(playlistId: playlistId)

        if youtubeTracks.isEmpty {
            isLoading = false
            errorMessage = "Failed to fetch playlist from YouTube"
            return (false, 0)
        }

        // Get existing videoIds in local playlist
        let existingVideoIds = Set(playlist.tracks.map { $0.videoId })

        // Filter tracks that exist in YouTube but not locally
        let newTracks = youtubeTracks.filter { !existingVideoIds.contains($0.videoId) }

        if newTracks.isEmpty {
            isLoading = false
            return (true, 0)
        }

        // Get current max sortIndex
        let sortedTracks = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
        var currentMaxIndex = sortedTracks.last?.sortIndex ?? -1

        // Add new tracks to playlist
        for track in newTracks {
            currentMaxIndex += 1
            track.playlist = playlist
            track.sortIndex = currentMaxIndex
            context.insert(track)
        }

        do {
            try context.save()
            isLoading = false
            return (true, newTracks.count)
        } catch {
            print("❌ Failed to save synced tracks: \(error)")
            errorMessage = "Failed to save synced tracks"
            isLoading = false
            return (false, 0)
        }
    }

    func createPlaylist(name: String, colorHex: String, urlString: String? = nil) {
        guard let context = modelContext else { return }

        // Get current max orderIndex
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.orderIndex, order: .reverse)])
        let playlists = (try? context.fetch(descriptor)) ?? []
        let maxIndex = playlists.first?.orderIndex ?? -1
        
        var youtubePlaylistId: String?
        if let urlString, !urlString.isEmpty {
            youtubePlaylistId = Self.extractPlaylistId(from: urlString)
        }

        let playlist = Playlist(name: name, themeColorHex: colorHex, orderIndex: maxIndex + 1, youtubePlaylistId: youtubePlaylistId)
        context.insert(playlist)

        do {
            try context.save()
            selectedPlaylist = playlist
        } catch {
            print("Failed to save playlist: \(error)")
        }
        
        // If we have a playlist ID, fetch tracks
        if let playlistId = youtubePlaylistId {
            isLoading = true
            Task {
                let tracks = await fetchPlaylistItems(playlistId: playlistId)
                
                // Ensure we are on main actor for context updates (Task inherits, but explicit is safer if method wasn't isolated)
                // MusicPlayerManager is @MainActor, so this is fine.
                for (index, track) in tracks.enumerated() {
                    track.playlist = playlist
                    track.sortIndex = index
                    context.insert(track)
                }
                
                do {
                    try context.save()
                    
                    // If we just created and selected this playlist, and it was empty initially,
                    // we might want to start playing if the user intended? 
                    // Usually creation doesn't auto-play, so we just populate it.
                    // But update UI state.
                } catch {
                    print("Failed to save imported tracks: \(error)")
                }
                isLoading = false
            }
        }
    }

    func renamePlaylist(_ playlist: Playlist, newName: String) {
        guard let context = modelContext else { return }
        playlist.name = newName
        
        do {
            try context.save()
        } catch {
            print("Failed to rename playlist: \(error)")
        }
    }

    func deletePlaylist(_ playlist: Playlist) {
        guard let context = modelContext else { return }

        if selectedPlaylist?.id == playlist.id {
            selectedPlaylist = nil
            currentTrack = nil
            Task {
                await stop()
            }
        }

        context.delete(playlist)

        do {
            try context.save()
        } catch {
            print("Failed to delete playlist: \(error)")
        }
    }

    // MARK: - Track Management

    func addTrack(urlString: String, to playlist: Playlist) async {
        guard let videoId = Self.extractVideoId(from: urlString) else {
            errorMessage = "Invalid YouTube URL"
            return
        }

        guard let context = modelContext else { return }

        isLoading = true
        errorMessage = nil

        // Fetch metadata
        let metadata = await fetchVideoMetadata(videoId: videoId)
        let title = metadata?.title ?? "Unknown Title"
        let thumbnailUrl = metadata?.thumbnailUrl

        // Get current max sortIndex for this playlist
        let sortedTracks = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
        let maxIndex = sortedTracks.last?.sortIndex ?? -1

        let track = MusicTrack(
            title: title,
            videoId: videoId,
            thumbnailUrl: thumbnailUrl,
            sortIndex: maxIndex + 1
        )
        track.playlist = playlist

        context.insert(track)

        do {
            try context.save()
        } catch {
            print("Failed to save track: \(error)")
            errorMessage = "Failed to save track"
        }

        isLoading = false
    }

    func deleteTrack(_ track: MusicTrack) {
        guard let context = modelContext else { return }

        if currentTrack?.id == track.id {
            playNextTrack()
        }

        context.delete(track)

        do {
            try context.save()
        } catch {
            print("Failed to delete track: \(error)")
        }
    }

    func reorderTracks(_ tracks: [MusicTrack]) {
        guard let context = modelContext else { return }

        for (index, track) in tracks.enumerated() {
            track.sortIndex = index
        }

        do {
            try context.save()
        } catch {
            print("Failed to save track order: \(error)")
        }
    }

    // MARK: - Playback Control

    func play(track: MusicTrack) {
        currentTrack = track
        Task {
            try? await youTubePlayer.load(source: .video(id: track.videoId))
        }
    }

    func togglePlayPause() {
        Task {
            if isPlaying {
                try? await youTubePlayer.pause()
            } else {
                // 이미 재생 중이거나 일시정지 상태인 경우 play()만 호출
                // (YouTube Playlist의 경우 load를 다시 하면 처음부터 시작됨)
                if currentTrack == nil, let playlist = selectedPlaylist {
                    if let playlistId = playlist.youtubePlaylistId, playlist.tracks.isEmpty {
                        // 플레이어가 준비된 상태라면 play()만 호출
                        try? await youTubePlayer.play()
                        
                        // 만약 play()를 했는데도 상태가 변경되지 않거나(처음 로드 시)
                        // 플레이어가 비어있다면 로드 수행
                        // (이 부분은 YouTubePlayerKit의 상태를 더 정확히 확인해야 하지만,
                        //  일단 play()를 먼저 시도하는 것이 핵심)
                        return
                    }
                    
                    let sortedTracks = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
                    if let firstTrack = sortedTracks.first {
                        play(track: firstTrack)
                        return
                    }
                }
                try? await youTubePlayer.play()
            }
        }
    }

    func stop() async {
        try? await youTubePlayer.stop()
        isPlaying = false
    }

    func playNextTrack() {
        if let playlist = selectedPlaylist, playlist.youtubePlaylistId != nil, playlist.tracks.isEmpty {
            Task { try? await youTubePlayer.evaluate(javaScript: .youTubePlayer(functionName: "nextVideo")) }
            return
        }
        
        guard let playlist = selectedPlaylist,
              let current = currentTrack else {
            return
        }

        let sortedTracks = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }

        guard let currentIndex = sortedTracks.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < sortedTracks.count {
            play(track: sortedTracks[nextIndex])
        } else if let firstTrack = sortedTracks.first {
            // Loop back to the first track
            play(track: firstTrack)
        }
    }

    func playPlaylist(_ playlist: Playlist) {
        // 이미 선택된 플레이리스트인 경우
        if selectedPlaylist?.id == playlist.id {
             togglePlayPause() 
             return
        }

        selectedPlaylist = playlist
        
        // YouTube Playlist인 경우 (트랙이 없을 때만 폴백)
        if let playlistId = playlist.youtubePlaylistId, playlist.tracks.isEmpty {
             Task { try? await youTubePlayer.load(source: .playlist(id: playlistId)) }
             return
        }

        // 일반 트랙 리스트인 경우
        let sortedTracks = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
        if let firstTrack = sortedTracks.first {
             play(track: firstTrack)
        }
    }

    func playPreviousTrack() {
        if let playlist = selectedPlaylist, playlist.youtubePlaylistId != nil, playlist.tracks.isEmpty {
            Task { try? await youTubePlayer.evaluate(javaScript: .youTubePlayer(functionName: "previousVideo")) }
            return
        }

        guard let playlist = selectedPlaylist,
              let current = currentTrack else {
            return
        }

        let sortedTracks = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }

        guard let currentIndex = sortedTracks.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        let prevIndex = currentIndex - 1
        if prevIndex >= 0 {
            play(track: sortedTracks[prevIndex])
        } else if let lastTrack = sortedTracks.last {
            // Loop to the last track
            play(track: lastTrack)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
