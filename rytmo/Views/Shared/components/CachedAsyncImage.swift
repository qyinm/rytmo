//
//  CachedAsyncImage.swift
//  rytmo
//
//  Created by hippoo on 12/9/25.
//

import SwiftUI

/// 캐싱을 지원하는 비동기 이미지 뷰
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        if let url = url {
            CachedAsyncImageInternal(url: url, content: content, placeholder: placeholder)
        } else {
            placeholder()
        }
    }
}

fileprivate struct CachedAsyncImageInternal<Content: View, Placeholder: View>: View {
    @StateObject private var loader: ImageLoader

    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    init(
        url: URL,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let nsImage = loader.image {
                content(Image(nsImage: nsImage))
            } else {
                placeholder()
            }
        }
    }
}

/// 편의 initializer - AsyncImage와 유사한 인터페이스
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { image in image },
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}
