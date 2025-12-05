//
//  PlaylistSelectorView.swift
//  rytmo
//
//  Created by hippoo on 12/4/25.
//

import SwiftUI
import SwiftData

// MARK: - Playlist Selector View

struct PlaylistSelectorView: View {

    @EnvironmentObject var musicPlayer: MusicPlayerManager
    @Query(sort: \Playlist.orderIndex) private var playlists: [Playlist]

    @State private var showingAddPlaylist: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var selectedColorHex: String = "FF6B6B"

    private let colorOptions = [
        "FF6B6B", // Red
        "4ECDC4", // Teal
        "FFE66D", // Yellow
        "95E1D3", // Mint
        "A8E6CF", // Light Green
        "DDA0DD", // Plum
        "87CEEB", // Sky Blue
        "F0E68C"  // Khaki
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Selected Playlist Header
            HStack {
                if let selected = musicPlayer.selectedPlaylist {
                    Text(selected.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                } else {
                    Text("Select a Playlist")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(playlists) { playlist in
                        playlistCircle(for: playlist)
                    }

                    // Add button
                    addPlaylistButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8) // Add space for selection rings
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Playlist Circle

    private func playlistCircle(for playlist: Playlist) -> some View {
        let isSelected = musicPlayer.selectedPlaylist?.id == playlist.id

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                musicPlayer.selectedPlaylist = playlist
            }
        }) {
            ZStack {
                // Focus Ring
                if isSelected {
                    Circle()
                        .stroke(Color(hex: playlist.themeColorHex).opacity(0.3), lineWidth: 4)
                        .frame(width: 38, height: 38)
                }
                
                // Main Circle
                Circle()
                    .fill(Color(hex: playlist.themeColorHex))
                    .frame(width: 28, height: 28)
                    .shadow(color: Color(hex: playlist.themeColorHex).opacity(0.3), radius: 3, x: 0, y: 2)
                    .overlay(
                        Group {
                            if isSelected {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    )
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(playlist.name)
        .contextMenu {
            Button(role: .destructive) {
                musicPlayer.deletePlaylist(playlist)
            } label: {
                Label("Delete Playlist", systemImage: "trash")
            }
        }
    }

    // MARK: - Add Playlist Button

    private var addPlaylistButton: some View {
        Button(action: {
            showingAddPlaylist = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .popover(isPresented: $showingAddPlaylist) {
            addPlaylistPopover
        }
    }

    // MARK: - Add Playlist Popover

    private var addPlaylistPopover: some View {
        VStack(spacing: 16) {
            Text("New Playlist")
                .font(.headline)

            TextField("Playlist Name", text: $newPlaylistName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            // Color picker
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32)), count: 4), spacing: 8) {
                ForEach(colorOptions, id: \.self) { colorHex in
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(selectedColorHex == colorHex ? Color.white : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedColorHex = colorHex
                        }
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    showingAddPlaylist = false
                    resetForm()
                }
                .buttonStyle(.bordered)

                Button("Create") {
                    createPlaylist()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPlaylistName.isEmpty)
            }
        }
        .padding()
        .frame(width: 240)
    }

    // MARK: - Actions

    private func createPlaylist() {
        musicPlayer.createPlaylist(name: newPlaylistName, colorHex: selectedColorHex)
        showingAddPlaylist = false
        resetForm()
    }

    private func resetForm() {
        newPlaylistName = ""
        selectedColorHex = "FF6B6B"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Playlist.self, configurations: config)

    // Add some sample playlists
    container.mainContext.insert(Playlist(name: "Morning Jams", themeColorHex: "FF6B6B", orderIndex: 0))
    container.mainContext.insert(Playlist(name: "Workout Beats", themeColorHex: "4ECDC4", orderIndex: 1))
    container.mainContext.insert(Playlist(name: "Chill Vibes", themeColorHex: "FFE66D", orderIndex: 2))

    return PlaylistSelectorView()
        .environmentObject(MusicPlayerManager())
        .modelContainer(container)
}