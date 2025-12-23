//
//  MenuBarMusicView.swift
//  rytmo
//
//  Created by hippoo on 12/23/25.
//

import SwiftUI
import SwiftData

// MARK: - Menu Bar Music View
/// 메뉴바 전용 미니멀 음악 플레이어
struct MenuBarMusicView: View {
    
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Query(sort: \Playlist.orderIndex) private var playlists: [Playlist]
    
    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0
    @State private var showTrackList: Bool = false
    @State private var showEmptyStateMessage: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 메인 플레이어
            mainPlayer
            
            // 트랙 리스트 (토글 가능)
            if showTrackList {
                Divider()
                    .padding(.top, 12)
                
                trackList
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
    }
    
    // MARK: - Main Player
    
    private var mainPlayer: some View {
        VStack(spacing: 14) {
            // 앨범 아트 + 트랙 정보
            HStack(spacing: 12) {
                // 앨범 아트
                if let thumbnailUrl = musicPlayer.currentTrack?.thumbnailUrl {
                    CachedAsyncImage(url: thumbnailUrl) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
                    .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        )
                }
                
                // 트랙 정보
                VStack(alignment: .leading, spacing: 4) {
                    if let title = musicPlayer.playbackTitle ?? musicPlayer.currentTrack?.title {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(2)
                    } else {
                        Text("재생 중인 곡이 없습니다")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let playlist = musicPlayer.selectedPlaylist {
                        Text(playlist.name)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 프로그레스 바
            progressBar
            
            // 컨트롤 버튼 + 트랙 리스트 토글
            HStack(spacing: 0) {
                // 트랙 리스트 토글 버튼 (왼쪽)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showTrackList.toggle()
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                        .foregroundColor(showTrackList ? .accentColor : .secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .help("트랙 리스트")
                
                Spacer()
                
                // 재생 컨트롤 (중앙)
                HStack(spacing: 20) {
                    Button(action: { 
                        handlePreviousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)
                    
                    Button(action: { 
                        handlePlayPause()
                    }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showEmptyStateMessage, arrowEdge: .bottom) {
                        emptyStatePopover
                    }
                    
                    Button(action: { 
                        handleNextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisableControls)
                }
                
                Spacer()
                
                // 빈 공간 (레이아웃 밸런스)
                Color.clear
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { isDragging ? dragValue : musicPlayer.currentTime },
                    set: { newValue in dragValue = newValue }
                ),
                in: 0...max(musicPlayer.duration, 0.1),
                onEditingChanged: { editing in
                    isDragging = editing
                    if !editing {
                        musicPlayer.seek(to: dragValue)
                    }
                }
            )
            .controlSize(.small)
            .disabled(shouldDisableControls)
            
            HStack {
                Text((isDragging ? dragValue : musicPlayer.currentTime).formattedTimeString())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(musicPlayer.duration.formattedTimeString())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Track List
    
    private var trackList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("트랙 리스트")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let playlist = musicPlayer.selectedPlaylist {
                    Text(playlist.name)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
            
            ScrollView {
                TrackListView(isMenuBar: true)
            }
            .frame(maxHeight: 200)
        }
    }
    
    // MARK: - Empty State Popover
    
    private var emptyStatePopover: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("곡을 추가하세요")
                .font(.system(size: 14, weight: .semibold))
            
            Text("트랙 리스트에서 곡을 추가하거나\n대시보드에서 플레이리스트를 관리하세요")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 220)
    }
    
    // MARK: - Actions
    
    private func handlePlayPause() {
        // 1. 플레이리스트가 없으면 첫 번째 플레이리스트 자동 선택
        if musicPlayer.selectedPlaylist == nil {
            if let firstPlaylist = playlists.first {
                withAnimation {
                    musicPlayer.selectedPlaylist = firstPlaylist
                }
            } else {
                // 플레이리스트가 하나도 없음
                showEmptyStateMessage = true
                return
            }
        }
        
        // 2. 선택된 플레이리스트에 곡이 없으면 트랙 리스트 열기
        if let playlist = musicPlayer.selectedPlaylist {
            let hasNoTracks = playlist.youtubePlaylistId == nil && playlist.tracks.isEmpty
            
            if hasNoTracks {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showTrackList = true
                }
                showEmptyStateMessage = true
                return
            }
        }
        
        // 3. 정상적으로 재생/일시정지
        musicPlayer.togglePlayPause()
    }
    
    private func handlePreviousTrack() {
        // 플레이리스트가 없으면 자동 선택
        if musicPlayer.selectedPlaylist == nil, let firstPlaylist = playlists.first {
            withAnimation {
                musicPlayer.selectedPlaylist = firstPlaylist
            }
        }
        musicPlayer.playPreviousTrack()
    }
    
    private func handleNextTrack() {
        // 플레이리스트가 없으면 자동 선택
        if musicPlayer.selectedPlaylist == nil, let firstPlaylist = playlists.first {
            withAnimation {
                musicPlayer.selectedPlaylist = firstPlaylist
            }
        }
        musicPlayer.playNextTrack()
    }
    
    // MARK: - Helpers
    
    private var shouldDisableControls: Bool {
        // 재생 버튼은 항상 활성화 (스마트하게 처리하므로)
        return false
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Playlist.self, configurations: config)
    
    let playlist = Playlist(name: "Focus Music", themeColorHex: "FF6B6B", orderIndex: 0)
    container.mainContext.insert(playlist)
    
    let musicPlayer = MusicPlayerManager()
    musicPlayer.selectedPlaylist = playlist
    
    return MenuBarMusicView()
        .environmentObject(musicPlayer)
        .modelContainer(container)
        .frame(width: 500)
        .padding()
}

