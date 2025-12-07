//
//  PlaylistView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI

struct PlaylistView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Playlists")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top, 20)
                
                ForEach(1...5, id: \.self) { i in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Awesome Playlist \(i)")
                                .font(.headline)
                            Text("24 songs • 1 hr 20 min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                            .opacity(0.0) // Visible on hover ideally
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                }
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    PlaylistView()
}
