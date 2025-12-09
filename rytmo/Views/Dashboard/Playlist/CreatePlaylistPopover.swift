//
//  CreatePlaylistPopover.swift
//  rytmo
//
//  Created by hippoo on 12/9/25.
//

import SwiftUI

struct CreatePlaylistPopover: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    
    @State private var name: String = ""
    @State private var youtubeUrl: String = ""
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
        VStack(alignment: .leading, spacing: 20) {
            Text("New Playlist")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                TextField("Untitled", text: $name)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUTUBE URL (OPTIONAL)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                TextField("https://youtube.com/playlist?list=...", text: $youtubeUrl)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("COLOR")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(24)), count: 8), spacing: 8) {
                    ForEach(colorOptions, id: \.self) { colorHex in
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(selectedColorHex == colorHex ? 0.5 : 0), lineWidth: 2)
                                    .padding(-2)
                            )
                            .onTapGesture {
                                selectedColorHex = colorHex
                            }
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
                
                Spacer()
                
                Button("Create") {
                    createPlaylist()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary)
                .cornerRadius(6)
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func createPlaylist() {
        musicPlayer.createPlaylist(name: name, colorHex: selectedColorHex, urlString: youtubeUrl)
        isPresented = false
    }
}
