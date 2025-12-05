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
        VStack(spacing: 30) {
            Spacer()

            // 로고 및 타이틀
            VStack(spacing: 16) {
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)

                Text("Rytmo")
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text("리듬감 있는 몰입을 위한 타이머")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 로그인 영역
            VStack(spacing: 20) {
                // 에러 메시지
                if let errorMessage = authManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)

                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: 400)
                    .background(.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Google 로그인 버튼
                Button(action: {
                    Task {
                        await authManager.signInWithGoogle()
                    }
                }) {
                    HStack(spacing: 12) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            // Google 로고 (SF Symbols 사용)
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                        }

                        Text(authManager.isLoading ? "로그인 중..." : "Google로 계속하기")
                            .font(.headline)
                    }
                    .frame(width: 280, height: 50)
                    .background(.white)
                    .foregroundStyle(.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                // 구분선
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)

                    Text("또는")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .frame(width: 280)
                .padding(.vertical, 8)

                // 익명 로그인 버튼
                Button(action: {
                    Task {
                        await authManager.signInAnonymously()
                    }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }

                        Text(authManager.isLoading ? "로그인 중..." : "익명으로 시작하기")
                            .font(.headline)
                    }
                    .frame(width: 280, height: 44)
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading)
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)

                Text("익명 로그인은 데이터가 저장되지 않습니다")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Dashboard View

struct DashboardView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 30) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("환영합니다!")
                        .font(.system(size: 32, weight: .bold))

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
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("로그아웃")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.white.opacity(0.5))
            .cornerRadius(12)

            // 메인 컨텐츠
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green.gradient)

                Text("로그인 성공!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Rytmo의 모든 기능을 사용할 수 있습니다.\n메뉴바에서 타이머를 시작해보세요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(40)

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [.green.opacity(0.05), .blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
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
