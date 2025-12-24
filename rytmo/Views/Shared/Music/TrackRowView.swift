//
//  TrackRowView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI

// MARK: - Track Row View

struct TrackRowView: View {

    let track: MusicTrack
    let isCurrentTrack: Bool
    let isPlaying: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onTap: () -> Void

    @State private var rotationAngle: Double = 0
    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // LP/Thumbnail
            lpThumbnail

            // Title
            HStack(spacing: 6) {
                Text(track.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)
                
                if isCurrentTrack && isPlaying {
                    LiveWaveformView(isPlaying: true, color: .accentColor)
                        .scaleEffect(0.7) // 트랙 리스트에 맞게 작게 조정
                }
            }

            Spacer()

            // Reorder and delete buttons (visible on hover)
            if isHovering {
                HStack(spacing: 4) {
                    // Move up button
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveUp)
                    .opacity(canMoveUp ? 1.0 : 0.3)

                    // Move down button
                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveDown)
                    .opacity(canMoveDown ? 1.0 : 0.3)

                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentTrack ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - LP Thumbnail

    private var lpThumbnail: some View {
        ZStack {
            if let thumbnailUrl = track.thumbnailUrl {
                CachedAsyncImage(url: thumbnailUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(rotationAngle))
                } placeholder: {
                    lpIcon
                }
            } else {
                lpIcon
            }
        }
        .onAppear {
            if isCurrentTrack && isPlaying {
                startRotation()
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if isCurrentTrack && newValue {
                startRotation()
            } else {
                stopRotation()
            }
        }
        .onChange(of: isCurrentTrack) { _, newValue in
            if newValue && isPlaying {
                startRotation()
            } else {
                stopRotation()
            }
        }
    }

    private var lpIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)

            // LP grooves
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                .frame(width: 24, height: 24)

            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                .frame(width: 16, height: 16)

            // Center hole
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 6, height: 6)
        }
        .rotationEffect(.degrees(rotationAngle))
    }

    private func startRotation() {
        guard isCurrentTrack && isPlaying else { return }

        withAnimation(
            .linear(duration: 3)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }

    private func stopRotation() {
        withAnimation(.linear(duration: 0)) {
            rotationAngle = 0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TrackRowView(
            track: {
                let track = MusicTrack(
                    title: "Lo-fi Hip Hop Radio - Beats to Relax/Study to",
                    videoId: "test123",
                    thumbnailUrl: nil,
                    sortIndex: 0
                )
                return track
            }(),
            isCurrentTrack: true,
            isPlaying: true,
            canMoveUp: false,
            canMoveDown: true,
            onDelete: {},
            onMoveUp: {},
            onMoveDown: {},
            onTap: {}
        )

        TrackRowView(
            track: {
                let track = MusicTrack(
                    title: "Rain Sounds for Sleep",
                    videoId: "test456",
                    thumbnailUrl: nil,
                    sortIndex: 1
                )
                return track
            }(),
            isCurrentTrack: false,
            isPlaying: false,
            canMoveUp: true,
            canMoveDown: false,
            onDelete: {},
            onMoveUp: {},
            onMoveDown: {},
            onTap: {}
        )
    }
    .padding()
    .frame(width: 340)
}
