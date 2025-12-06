//
//  ContentView.swift
//  rytmo
//
//  Created by hippoo on 12/3/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var authManager: AuthManager

    // MARK: - Body

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                DashboardView()
            } else {
                LoginView()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// MARK: - Login View

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

// MARK: - Dashboard View

struct DashboardView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("환영합니다!")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let userId = authManager.currentUser?.uid {
                        Text("사용자 ID: \(String(userId.prefix(8)))...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // 로그아웃 버튼
                Button(action: {
                    authManager.signOut()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.caption)
                        Text("로그아웃")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .foregroundStyle(.primary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 1),
                alignment: .bottom
            )

            // 메인 컨텐츠
            VStack(spacing: 24) {
                Spacer()

                Image("RytmoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)

                VStack(spacing: 12) {
                    Text("준비 완료")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Rytmo의 모든 기능을 사용할 수 있습니다.\n메뉴바에서 타이머를 시작해보세요.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Previews

#Preview("Login View") {
    LoginView()
        .environmentObject(AuthManager())
}

#Preview("Dashboard View") {
    DashboardView()
        .environmentObject(AuthManager())
}
