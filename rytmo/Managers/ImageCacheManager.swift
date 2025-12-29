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
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSURL, NSImage>()

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
    }
}

/// Image loader (asynchronous download and caching)
final class ImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false

    private let url: URL
    private let cache = ImageCacheManager.shared

    init(url: URL) {
        self.url = url
        loadImage()
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

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                if let downloadedImage = NSImage(data: data) {
                    // Save to cache
                    cache.set(downloadedImage, for: url)

                    self.image = downloadedImage
                }
            } catch {
                print("Failed to load image: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }
}
