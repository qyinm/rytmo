//
//  SideRailView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct SideRailView: View {
    @Binding var selection: DashboardSelection?
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Icon
            Button {
                // Navigate to settings on profile click? or just visual
            } label: {
                ZStack {
                    AsyncImage(url: getUserProfilePictureURL()) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 10)
                .opacity(0.5)
            
            // Navigation Icons
            Group {
                railButton(icon: "house", selectedIcon: "house.fill", selectionValue: .home)
                
                railButton(icon: "music.note", selectedIcon: "music.note", selectionValue: .allPlaylists, isSelected: isPlaylistSelected)
            }
            
            Spacer()
            
            railButton(icon: "gearshape", selectedIcon: "gearshape.fill", selectionValue: .settings)
                .padding(.bottom, 16)
        }
        .frame(width: 50)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.primary.opacity(0.05)),
            alignment: .trailing
        )
        .zIndex(1)
    }
    
    private var isPlaylistSelected: Bool {
        if case .allPlaylists = selection { return true }
        if case .playlist = selection { return true }
        return false
    }
    
    private func railButton(icon: String, selectedIcon: String, selectionValue: DashboardSelection, isSelected: Bool? = nil) -> some View {
        let selected = isSelected ?? (selection == selectionValue)
        
        return Button {
            selection = selectionValue
        } label: {
            ZStack {
                if selected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 30, height: 30)
                }
                
                Image(systemName: selected ? selectedIcon : icon)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .opacity(selected ? 1.0 : 0.6)
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(String(describing: selectionValue).capitalized)
    }
}
