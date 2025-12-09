//
//  ImageCacheManager.swift
//  rytmo
//
//  Created by hippoo on 12/9/25.
//

import SwiftUI
import AppKit
import Combine

/// 이미지 캐싱을 위한 싱글톤 매니저
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        // 메모리 제한 설정 (약 50MB)
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    /// 캐시에서 이미지 가져오기
    func get(url: URL) -> NSImage? {
        return cache.object(forKey: url as NSURL)
    }

    /// 캐시에 이미지 저장
    func set(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    /// 캐시 비우기
    func clear() {
        cache.removeAllObjects()
    }
}

/// 이미지 로더 (비동기 다운로드 및 캐싱)
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
        // 캐시에서 먼저 확인
        if let cachedImage = cache.get(url: url) {
            self.image = cachedImage
            return
        }

        // 캐시에 없으면 다운로드
        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                if let downloadedImage = NSImage(data: data) {
                    // 캐시에 저장
                    cache.set(downloadedImage, for: url)

                    await MainActor.run {
                        self.image = downloadedImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                print("Failed to load image: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
