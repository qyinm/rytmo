//
//  ImageCacheManager.swift
//  rytmo
//
//  Created by hippoo on 12/9/25.
//

import SwiftUI
import AppKit
import Combine

/// Singleton manager for image caching
@MainActor
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSURL, NSImage>()
    private var inFlightTasks: [URL: Task<NSImage?, Never>] = [:]

    private init() {
        // Memory limit setting (approx. 50MB)
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    /// Get image from cache
    func get(url: URL) -> NSImage? {
        return cache.object(forKey: url as NSURL)
    }

    /// Save image to cache
    func set(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    /// Clear cache
    func clear() {
        cache.removeAllObjects()
        inFlightTasks.values.forEach { $0.cancel() }
        inFlightTasks.removeAll()
    }

    /// Load image with in-flight request deduplication.
    func loadImage(url: URL) async -> NSImage? {
        if let cached = get(url: url) {
            return cached
        }

        if let existingTask = inFlightTasks[url] {
            return await existingTask.value
        }

        let task = Task<NSImage?, Never> {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return nil }
                return NSImage(data: data)
            } catch {
                print("Failed to load image: \(error.localizedDescription)")
                return nil
            }
        }

        inFlightTasks[url] = task
        let downloaded = await task.value
        inFlightTasks[url] = nil

        if let downloaded {
            set(downloaded, for: url)
        }

        return downloaded
    }
}

/// Image loader (asynchronous download and caching)
final class ImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false

    private let url: URL
    private let cache = ImageCacheManager.shared
    private var loadTask: Task<Void, Never>?

    init(url: URL) {
        self.url = url
        loadImage()
    }

    deinit {
        loadTask?.cancel()
    }

    @MainActor
    private func loadImage() {
        // Check cache first
        if let cachedImage = cache.get(url: url) {
            self.image = cachedImage
            return
        }

        // Download if not in cache
        isLoading = true

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let downloadedImage = await cache.loadImage(url: url)
            guard !Task.isCancelled else { return }
            self.image = downloadedImage
            self.isLoading = false
        }
    }
}
