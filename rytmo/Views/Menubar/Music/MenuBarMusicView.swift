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
    @StateObject private var audioManager = AudioManager()
    
    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0
    @State private var showTrackList: Bool = false
    @State private var showOutputList: Bool = false
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
            }
            
            // 출력 기기 리스트 (이미지 준수 - 토글 가능)
            if showOutputList {
                Divider()
                    .padding(.top, 12)
                
                outputDeviceList
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
    }
    
    // MARK: - Main Player
    
    private var mainPlayer: some View {
        VStack(spacing: 12) {
            // 상단: 앨범 아트 + 트랙 정보 + 비주얼라이저
            HStack(spacing: 12) {
                // 앨범 아트
                if let thumbnailUrl = musicPlayer.currentTrack?.thumbnailUrl {
                    CachedAsyncImage(url: thumbnailUrl) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 52, height: 52)
                    .cornerRadius(8)
                    .clipped()
                    .shadow(radius: 2)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        )
                }
                
                // 트랙 정보
                VStack(alignment: .leading, spacing: 2) {
                    if let title = musicPlayer.playbackTitle ?? musicPlayer.currentTrack?.title {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    } else {
                        Text("재생 중인 곡이 없습니다")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let playlist = musicPlayer.selectedPlaylist {
                        Text(playlist.name)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 오른쪽 끝: 비주얼라이저 아이콘 (인터랙티브 파형)
                if musicPlayer.isPlaying {
                    LiveWaveformView(isPlaying: true, color: .accentColor)
                        .padding(.trailing, 4)
                }
            }
            
            // 중앙: 프로그레스 바 (이미지 준수: 시간과 슬라이더를 한 줄에)
            HStack(spacing: 8) {
                Text((isDragging ? dragValue : musicPlayer.currentTime).formattedTimeString())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
                
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
                .controlSize(.mini)
                .disabled(shouldDisableControls)
                
                Text("-" + (musicPlayer.duration - (isDragging ? dragValue : musicPlayer.currentTime)).formattedTimeString())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }
            
            // 하단: 컨트롤 버튼들
            HStack(spacing: 0) {
                // 트랙 리스트 버튼 (왼쪽)
                Button(action: {
                    showTrackList.toggle()
                    if showTrackList { showOutputList = false }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                        .foregroundColor(showTrackList ? .accentColor : .secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 중앙 컨트롤
                HStack(spacing: 24) {
                    Button(action: { handlePreviousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { handlePlayPause() }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showEmptyStateMessage, arrowEdge: .bottom) {
                        emptyStatePopover
                    }
                    
                    Button(action: { handleNextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                // 오디오 출력 선택기 버튼 (이미지 준수 - 토글로 변경)
                Button(action: {
                    showOutputList.toggle()
                    if showOutputList { showTrackList = false }
                }) {
                    Image(systemName: audioManager.currentDeviceIcon)
                        .font(.system(size: 16))
                        .foregroundColor(showOutputList ? .accentColor : .secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Output Device List
    
    private var outputDeviceList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Outputs")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                ForEach(audioManager.outputDevices) { device in
                    Button(action: {
                        audioManager.setOutputDevice(device.id)
                    }) {
                        HStack(spacing: 12) {
                            let isCurrent = device.id == audioManager.currentDeviceID
                            
                            // 장치 아이콘
                            ZStack {
                                Circle()
                                    .fill(isCurrent ? Color.accentColor : Color.primary.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: device.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(isCurrent ? .white : .primary)
                            }
                            
                            Text(device.name)
                                .font(.system(size: 14, weight: isCurrent ? .semibold : .regular))
                                .foregroundColor(isCurrent ? .primary : .secondary)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            audioManager.refreshDevices()
        }
    }
    
    // MARK: - Track List
    
    private var trackList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("트랙 리스트")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let playlist = musicPlayer.selectedPlaylist {
                    Text(playlist.name)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 6)
            
            ScrollView {
                TrackListView(isMenuBar: true)
            }
            .frame(maxHeight: 160)
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
                showTrackList = true
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

