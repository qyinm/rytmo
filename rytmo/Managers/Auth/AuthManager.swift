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
        // Register Firebase Auth state listener
        registerAuthStateHandler()

        // Check current user (Auto Login)
        checkCurrentUser()
    }

    deinit {
        // Remove listener
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    // MARK: - Auth State Listener

    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                
                // If user is Google user, restore previous sign in to refresh tokens/scopes
                if let user = user, user.providerData.contains(where: { $0.providerID == "google.com" }) {
                    do {
                        _ = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                        GoogleCalendarManager.shared.checkPermission()
                    } catch {
                        print("ℹ️ Google restore sign-in failed or not needed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Public Methods

    /// Check current login status
    func checkCurrentUser() {
        currentUser = Auth.auth().currentUser

        if let user = currentUser {
            print("✅ Automatic login successful: \(user.uid)")
        } else {
            print("ℹ️ No logged-in user")
        }
    }

    /// Firebase Anonymous Login
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signInAnonymously()
            currentUser = result.user

            print("✅ Anonymous login successful: \(result.user.uid)")

        } catch {
            let nsError = error as NSError
            errorMessage = formatErrorMessage(nsError)
            print("❌ Anonymous login failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Google Login
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Get Google Client ID
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Firebase Client ID not found."
                ])
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // 3. Get current window (macOS)
            guard let window = NSApplication.shared.windows.first else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Window not found."
                ])
            }

            // 4. Execute Google Sign-In with Calendar Scope
            let calendarScope = "https://www.googleapis.com/auth/calendar.readonly"
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: [calendarScope]
            )

            // 5. Get ID Token and Access Token
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "AuthManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Could not get Google ID Token."
                ])
            }

            let accessToken = result.user.accessToken.tokenString

            // 6. Create Firebase Credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            // 7. Sign in to Firebase Auth
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user

            print("✅ Google login successful: \(authResult.user.uid)")
            if let email = authResult.user.email {
                print("   Email: \(email)")
            }

        } catch let error as NSError {
            // Handle Google Sign-In cancellation
            if error.domain == "com.google.GIDSignIn" && error.code == -5 {
                errorMessage = "Login canceled."
                print("ℹ️ Google login canceled")
            } else {
                errorMessage = formatErrorMessage(error)
                print("❌ Google login failed: \(error.localizedDescription)")
            }
        }

        isLoading = false
    }

    /// Logout
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            errorMessage = nil

            print("✅ Logout successful")

        } catch {
            errorMessage = "Logout failed: \(error.localizedDescription)"
            print("❌ Logout failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Localize Firebase error messages
    private func formatErrorMessage(_ error: NSError) -> String {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return "An unknown error occurred."
        }

        switch errorCode {
        case .networkError:
            return "Please check your network connection."
        case .userNotFound:
            return "User not found."
        case .invalidEmail:
            return "Email format is incorrect."
        case .emailAlreadyInUse:
            return "Email already in use."
        case .weakPassword:
            return "Password is too weak."
        case .wrongPassword:
            return "Password is incorrect."
        case .tooManyRequests:
            return "Too many requests. Please try again later."
        case .userDisabled:
            return "Disabled account."
        case .operationNotAllowed:
            return "This operation is not allowed."
        default:
            return "Login failed: \(error.localizedDescription)"
        }
    }
}
