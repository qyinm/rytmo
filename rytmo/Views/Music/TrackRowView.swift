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
    let onDelete: () -> Void
    let onTap: () -> Void

    @State private var rotationAngle: Double = 0
    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            // LP/Thumbnail
            lpThumbnail

            // Title
            Text(track.title)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(isCurrentTrack ? .accentColor : .primary)

            Spacer()

            // Delete button (visible on hover)
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentTrack ? Color.accentColor.opacity(0.1) : Color.clear)
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
                AsyncImage(url: thumbnailUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .rotationEffect(.degrees(rotationAngle))
                    case .failure, .empty:
                        lpIcon
                    @unknown default:
                        lpIcon
                    }
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
            onDelete: {},
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
            onDelete: {},
            onTap: {}
        )
    }
    .padding()
    .frame(width: 340)
}
