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

            // 로고 및 타이틀
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

                    Text("리듬감 있는 몰입을 위한 타이머")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 로그인 영역
            VStack(spacing: 16) {
                // 에러 메시지
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

                // Google 로그인 버튼
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

                        Text(authManager.isLoading ? "로그인 중..." : "Google로 계속하기")
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

                // 구분선
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)

                    Text("또는")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 1)
                }
                .frame(width: 340)

                // 익명 로그인 버튼
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

                        Text(authManager.isLoading ? "로그인 중..." : "익명으로 시작하기")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(width: 340, height: 44)
                    .background(.black)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)

                Text("익명 로그인은 데이터가 저장되지 않습니다")
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
