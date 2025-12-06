//
//  AuthManager.swift
//  rytmo
//
//  Created by hippoo on 12/5/25.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import AppKit
import FirebaseCore

@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var isLoggedIn: Bool {
        currentUser != nil
    }

    // MARK: - Private Properties

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    // MARK: - Initialization

    init() {
        // Firebase Auth 상태 리스너 등록
        registerAuthStateHandler()

        // 현재 사용자 확인 (자동 로그인)
        checkCurrentUser()
    }

    deinit {
        // 리스너 해제
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    // MARK: - Auth State Listener

    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    // MARK: - Public Methods

    /// 현재 로그인 상태 확인
    func checkCurrentUser() {
        currentUser = Auth.auth().currentUser

        if let user = currentUser {
            print("✅ 자동 로그인 성공: \(user.uid)")
        } else {
            print("ℹ️ 로그인된 사용자 없음")
        }
    }

    /// Firebase 익명 로그인
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signInAnonymously()
            currentUser = result.user

            print("✅ 익명 로그인 성공: \(result.user.uid)")

        } catch {
            let nsError = error as NSError
            errorMessage = formatErrorMessage(nsError)
            print("❌ 익명 로그인 실패: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Google 로그인
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Google Client ID 가져오기
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Firebase Client ID를 찾을 수 없습니다."
                ])
            }

            // 2. GIDConfiguration 설정
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // 3. 현재 윈도우 가져오기 (macOS)
            guard let window = NSApplication.shared.windows.first else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "윈도우를 찾을 수 없습니다."
                ])
            }

            // 4. Google Sign-In 실행
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)

            // 5. ID Token과 Access Token 가져오기
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Google ID Token을 가져올 수 없습니다."
                ])
            }

            let accessToken = result.user.accessToken.tokenString

            // 6. Firebase Credential 생성
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            // 7. Firebase Auth에 로그인
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user

            print("✅ Google 로그인 성공: \(authResult.user.uid)")
            if let email = authResult.user.email {
                print("   이메일: \(email)")
            }

        } catch let error as NSError {
            // Google Sign-In 취소 처리
            if error.domain == "com.google.GIDSignIn" && error.code == -5 {
                errorMessage = "로그인이 취소되었습니다."
                print("ℹ️ Google 로그인 취소됨")
            } else {
                errorMessage = formatErrorMessage(error)
                print("❌ Google 로그인 실패: \(error.localizedDescription)")
            }
        }

        isLoading = false
    }

    /// 로그아웃
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            errorMessage = nil

            print("✅ 로그아웃 성공")

        } catch {
            errorMessage = "로그아웃 실패: \(error.localizedDescription)"
            print("❌ 로그아웃 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Firebase 에러 메시지 한글화
    private func formatErrorMessage(_ error: NSError) -> String {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return "알 수 없는 오류가 발생했습니다."
        }

        switch errorCode {
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .userNotFound:
            return "사용자를 찾을 수 없습니다."
        case .invalidEmail:
            return "이메일 형식이 올바르지 않습니다."
        case .emailAlreadyInUse:
            return "이미 사용 중인 이메일입니다."
        case .weakPassword:
            return "비밀번호가 너무 약합니다."
        case .wrongPassword:
            return "비밀번호가 올바르지 않습니다."
        case .tooManyRequests:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
        case .userDisabled:
            return "비활성화된 계정입니다."
        case .operationNotAllowed:
            return "이 작업은 허용되지 않습니다."
        default:
            return "로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }
}
