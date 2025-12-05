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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(playlists) { playlist in
                        playlistCircle(for: playlist)
                    }

                    // Add button
                    addPlaylistButton
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Playlist Circle

    private func playlistCircle(for playlist: Playlist) -> some View {
        let isSelected = musicPlayer.selectedPlaylist?.id == playlist.id

        return Button(action: {
            musicPlayer.selectedPlaylist = playlist
        }) {
            Circle()
                .fill(Color(hex: playlist.themeColorHex))
                .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.8 : 0), lineWidth: 2)
                )
                .shadow(color: isSelected ? Color(hex: playlist.themeColorHex).opacity(0.5) : .clear, radius: 4)
                .help(playlist.name)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                )
        }
        .buttonStyle(.plain)
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