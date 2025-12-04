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

// MARK: - Noembed Response

struct NoembedResponse: Codable {
    let title: String?
    let thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case title
        case thumbnailUrl = "thumbnail_url"
    }
}

// MARK: - Music Player Manager

@MainActor
class MusicPlayerManager: ObservableObject {

    // MARK: - Published Properties

    @Published var youTubePlayer: YouTubePlayer
    @Published var currentTrack: MusicTrack?
    @Published var selectedPlaylist: Playlist?
    @Published var isPlaying: Bool = false
    @Published var volume: Double = 0.7
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // YouTubePlayer configuration
        let configuration = YouTubePlayer.Configuration(
            fullscreenMode: .system
        )
        self.youTubePlayer = YouTubePlayer(configuration: configuration)

        setupPlayerObservation()
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
                switch state {
                case .playing:
                    self?.isPlaying = true
                case .paused, .ended, .unstarted, .cued:
                    self?.isPlaying = false
                    if state == .ended {
                        self?.playNextTrack()
                    }
                default:
                    break
                }
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

    // MARK: - Playlist Management

    func createPlaylist(name: String, colorHex: String) {
        guard let context = modelContext else { return }

        // Get current max orderIndex
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\.orderIndex, order: .reverse)])
        let playlists = (try? context.fetch(descriptor)) ?? []
        let maxIndex = playlists.first?.orderIndex ?? -1

        let playlist = Playlist(name: name, themeColorHex: colorHex, orderIndex: maxIndex + 1)
        context.insert(playlist)

        do {
            try context.save()
            selectedPlaylist = playlist
        } catch {
            print("Failed to save playlist: \(error)")
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
            try? await youTubePlayer.cue(source: .video(id: track.videoId))
            try? await youTubePlayer.play()
        }
    }

    func togglePlayPause() {
        Task {
            if isPlaying {
                try? await youTubePlayer.pause()
            } else {
                if currentTrack == nil, let playlist = selectedPlaylist {
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

    func playPreviousTrack() {
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

    func setVolume(_ newVolume: Double) {
        volume = newVolume
        // Note: YouTubePlayerKit 2.x doesn't expose volume control directly
        // Volume is controlled by the system
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
