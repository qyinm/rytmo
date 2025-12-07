//
//  UserProfileImage.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI
import FirebaseAuth

struct UserProfileImage: View {
    let size: CGFloat
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        let photoURL = authManager.currentUser?.photoURL
        
        ZStack {
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        placeholder
                    } else {
                        placeholder // Loading state
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var placeholder: some View {
        ZStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundColor(.gray)
            
            // Overlay initial if desired, matching previous DashboardView logic
            // Previous logic: Overlay Text on TOP of the final result. 
            // Here we put it on placeholder. If image loads, no text. This is an improvement.
            if let user = authManager.currentUser {
               Text(String(user.uid.prefix(1)).uppercased())
                   .font(.system(size: size * 0.45, weight: .bold)) // Scale font with size
                   .foregroundColor(.white)
            } else {
               Text("U")
                   .font(.system(size: size * 0.45, weight: .bold))
                   .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    UserProfileImage(size: 32)
        .environmentObject(AuthManager())
}
