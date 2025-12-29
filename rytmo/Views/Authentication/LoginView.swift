//
//  LoginView.swift
//  rytmo
//
//  Created by hippoo on 12/7/25.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and Title
            VStack(spacing: 24) {
                Image("RytmoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)

                VStack(spacing: 12) {
                    Text("Rytmo")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Timer for Rhythmic Immersion")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Login Area
            VStack(spacing: 16) {
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)

                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: 340)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }

                // Google Login Button
                Button(action: {
                    Task {
                        await authManager.signInWithGoogle()
                    }
                }) {
                    HStack(spacing: 10) {
                        if authManager.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "g.circle.fill")
                                .font(.body)
                        }

                        Text(authManager.isLoading ? "Logging in..." : "Continue with Google")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(width: 340, height: 44)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .foregroundStyle(.primary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                // Divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)

                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                }
                .frame(width: 340)

                // Anonymous Login Button
                Button(action: {
                    Task {
                        await authManager.signInAnonymously()
                    }
                }) {
                    HStack(spacing: 10) {
                        if authManager.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                                .tint(.primary)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.body)
                        }

                        Text(authManager.isLoading ? "Logging in..." : "Start Anonymously")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(width: 340, height: 44)
                    .background(.black)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                Text("Anonymous login data is not saved")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
