import Foundation
import Supabase
import Combine // For @Published
import AuthenticationServices // Import for ASAuthorizationAppleIDCredential

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil // Supabase User type
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    private var currentNonce: String? // To store the nonce during Apple Sign In
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Start listening to auth changes in a Task
        Task {
            await listenToAuthStateChanges()
        }
        checkInitialSession()
    }

    private func listenToAuthStateChanges() async { // Mark as async
        // Use a for-await loop to consume the AsyncStream
        for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
            // Ensure UI updates are on the main thread
            await MainActor.run {
                switch event {
                case .signedIn:
                    self.isAuthenticated = true
                    self.currentUser = session?.user
                    self.errorMessage = nil
                    print("User signed in: \(String(describing: session?.user.id))")
                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUser = nil
                    // Don't clear errorMessage on explicit sign out, might be useful for some flows
                    print("User signed out.")
                case .passwordRecovery:
                    // Handle password recovery if needed, e.g. show a message
                    print("Password recovery event.")
                case .tokenRefreshed:
                    // Session token was refreshed. Update user if necessary.
                    self.currentUser = session?.user
                    print("Token refreshed.")
                case .userUpdated:
                    self.currentUser = session?.user
                    print("User details updated.")
                // As of supabase-swift 2.0.0, .initialSession and .userDeleted were removed from AuthChangeEvent
                // .initialSession logic is covered by checkInitialSession()
                // .userDeleted would typically lead to a .signedOut event or require specific handling if your app needs it
                @unknown default:
                    print("Unknown auth event: \(event)")
                }
            }
        }
    }

    private func checkInitialSession() {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.currentUser = session.user
                    self.errorMessage = nil
                    print("Initial session loaded for user: \(String(describing: session.user.id))")
                }
            } catch {
                // No active session or error fetching it. User is not authenticated.
                // This state is usually handled by .signedOut from authStateChanges if there's no session.
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    print("No initial session found or error: \(error.localizedDescription)")
                }
            }
        }
    }

    // Placeholder for future methods
    func signInWithEmail(email: String, password: String) {
        Task {
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            do {
                _ = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
                // Auth state change listener will update isAuthenticated and currentUser
                print("Sign in successful for email: \(email)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("Sign in error: \(error.localizedDescription)")
                }
            }
        }
    }

    func signUpWithEmail(email: String, password: String) {
        Task {
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            do {
                // Supabase signUp might return a session if auto-confirm is on, or if email confirmation is off.
                // If email confirmation is required, user won't be signedIn until confirmed.
                // The authStateChanges listener should handle the session update.
                _ = try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
                print("Sign up request successful for email: \(email). Check email for confirmation if enabled.")
                DispatchQueue.main.async {
                    self.isLoading = false
                    // Optionally, you could set a message like "Please check your email to confirm your account."
                    // For now, if successful, authStateChanges will handle the new user state or lack thereof until confirmation.
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("Sign up error: \(error.localizedDescription)")
                }
            }
        }
    }

    func signOut() {
        Task {
            DispatchQueue.main.async {
                self.isLoading = true // Optional: show loading during sign out
            }
            do {
                try await SupabaseManager.shared.client.auth.signOut()
                // Auth state change listener will update isAuthenticated and currentUser
                print("Sign out successful.")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription // Show error if sign out fails
                    print("Sign out error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Sign in with Apple

    // Helper to generate a random nonce string
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate random bytes: \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    func generateAndStoreNonce() -> String {
        let nonce = randomNonceString()
        self.currentNonce = nonce
        return nonce
    }

    func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        switch result {
        case .success(let authResults):
            switch authResults.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                guard let idTokenData = appleIDCredential.identityToken,
                      let idToken = String(data: idTokenData, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Could not retrieve ID token from Apple sign-in."
                        print("Sign in with Apple error: Missing ID token")
                    }
                    return
                }
                
                // Optionally, capture fullName if provided (usually only on first sign-up)
                // let fullName = appleIDCredential.fullName
                // let email = appleIDCredential.email
                // You might want to pass these to Supabase or store them if it's a new user

                guard let nonce = self.currentNonce else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Nonce missing during Apple sign-in completion."
                        print("Sign in with Apple error: Nonce missing post-authorization")
                    }
                    return
                }
                signInWithSupabaseUsingApple(idToken: idToken, nonce: nonce)
                
            default:
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Unhandled Apple credential type."
                    print("Sign in with Apple error: Unhandled credential type")
                }
            }
            
        case .failure(let error):
            DispatchQueue.main.async {
                self.isLoading = false
                // Don't show error if user cancelled (error code 1001 for ASAuthorizationError.canceled)
                if (error as? ASAuthorizationError)?.code != .canceled {
                    self.errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
                }
                print("Sign in with Apple error: \(error.localizedDescription)")
            }
        }
    }
    
    private func signInWithSupabaseUsingApple(idToken: String, nonce: String) {
        Task {
            // TODO: Implement proper nonce generation and handling.
            // The nonce used here should be the same one provided in the ASAuthorizationAppleIDRequest.
            // let temporaryNonce = "TEMPORARY_NONCE_FIXME" // Placeholder - MUST BE REPLACED

            do {
                _ = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .apple, 
                        idToken: idToken,
                        nonce: nonce // Use the passed nonce
                    )
                )
                // Auth state change listener will update isAuthenticated and currentUser
                print("Successfully signed in with Apple ID token via Supabase.")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Supabase Apple sign-in failed: \(error.localizedDescription)"
                    print("Supabase Apple sign-in error: \(error.localizedDescription)")
                    self.currentNonce = nil // Clear nonce on failure
                }
            }
        }
    }

    // MARK: - Password Reset
    func sendPasswordReset(email: String, completion: @escaping () -> Void) {
        Task {
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            do {
                try await SupabaseManager.shared.client.auth.resetPasswordForEmail(email)
                print("Password reset email requested for: \(email)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    // errorMessage will be nil, indicating success to the view
                    completion() // Call completion to trigger alert in view
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("Password reset error: \(error.localizedDescription)")
                    completion() // Call completion to trigger alert in view (with error message)
                }
            }
        }
    }

    // ... other methods for Sign in with Apple, password reset etc.
} 