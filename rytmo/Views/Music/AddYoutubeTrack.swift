//
//  AddTrackPopover.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI

struct AddYoutubeTrack: View {
    @Binding var isPresented: Bool
    @Binding var urlString: String
    @EnvironmentObject var musicPlayer: MusicPlayerManager
    let playlist: Playlist
    var onAdd: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add YouTube Track")
                .font(.headline)

            TextField("YouTube URL", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .frame(width: 280)
                .onSubmit {
                    performAdd()
                }

            if let error = musicPlayer.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if musicPlayer.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                    urlString = ""
                    musicPlayer.errorMessage = nil
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button("Add") {
                    performAdd()
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlString.isEmpty || musicPlayer.isLoading)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 320)
    }
    
    private func performAdd() {
        if urlString.isEmpty { return }
        
        Task {
            // If onAdd closure is provided, use it (custom behavior)
            // Otherwise default to musicPlayer manager call
            if let onAdd = onAdd {
                onAdd()
                return
            }

            await musicPlayer.addTrack(urlString: urlString, to: playlist)

            if musicPlayer.errorMessage == nil {
                isPresented = false
                urlString = ""
            }
        }
    }
}
