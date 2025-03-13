import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        checkAuthenticationState()
    }
    
    func signIn(with credentials: UserCredentials) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await auth.signIn(withEmail: credentials.email, password: credentials.password)
            let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
            
            if let userData = try? userDoc.data(as: UserProfile.self) {
                userProfile = userData
                isAuthenticated = true
                
                // Update last login
                try? await db.collection("users").document(result.user.uid).updateData([
                    "lastLoginAt": Date()
                ])
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signUp(with credentials: UserCredentials, username: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await auth.createUser(withEmail: credentials.email, password: credentials.password)
            
            let newUser = UserProfile(
                id: result.user.uid,
                username: username,
                email: credentials.email,
                profileImageUrl: nil,
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            try await db.collection("users").document(result.user.uid).setData(from: newUser)
            userProfile = newUser
            isAuthenticated = true
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GoogleSignInClientID") as? String else {
            throw AuthError.missingGoogleClientID
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthError.presentationError
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingGoogleToken
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await auth.signIn(with: credential)
            
            // Check if user exists
            let userDoc = try? await db.collection("users").document(authResult.user.uid).getDocument()
            
            if let userData = try? userDoc?.data(as: UserProfile.self) {
                userProfile = userData
            } else {
                // Create new user profile
                let newUser = UserProfile(
                    id: authResult.user.uid,
                    username: authResult.user.displayName ?? "User",
                    email: authResult.user.email ?? "",
                    profileImageUrl: authResult.user.photoURL?.absoluteString,
                    createdAt: Date(),
                    lastLoginAt: Date()
                )
                try await db.collection("users").document(authResult.user.uid).setData(from: newUser)
                userProfile = newUser
            }
            
            isAuthenticated = true
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            isAuthenticated = false
            userProfile = nil
        } catch {
            self.error = error
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func updateProfile(updates: [String: Any]) async throws {
        guard let userId = userProfile?.id else { throw AuthError.userNotFound }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await db.collection("users").document(userId).updateData(updates)
            
            // Refresh user profile
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let userData = try? userDoc.data(as: UserProfile.self) {
                userProfile = userData
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func checkAuthenticationState() {
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            Task {
                if let user = user {
                    do {
                        let userDoc = try await self.db.collection("users").document(user.uid).getDocument()
                        if let userData = try? userDoc.data(as: UserProfile.self) {
                            await MainActor.run {
                                self.userProfile = userData
                                self.isAuthenticated = true
                            }
                        }
                    } catch {
                        self.error = error
                    }
                } else {
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.userProfile = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Instagram Authentication
    
    func signInWithInstagram() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "InstagramClientID") as? String,
              let redirectURI = Bundle.main.object(forInfoDictionaryKey: "InstagramRedirectURI") as? String else {
            throw AuthError.missingInstagramConfig
        }
        
        // Build Instagram OAuth URL
        var components = URLComponents(string: "https://api.instagram.com/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "user_profile,user_media"),
            URLQueryItem(name: "response_type", value: "code")
        ]
        
        guard let authURL = components?.url else {
            throw AuthError.invalidInstagramURL
        }
        
        // Handle Instagram OAuth flow
        // Note: This requires implementing a custom WebView and URL scheme handling
        // The actual implementation would be in a separate InstagramAuthService
        
        // For now, we'll throw an error
        throw AuthError.instagramAuthNotImplemented
    }
    
    // MARK: - Profile Completion
    
    func completeProfile(fashionInterests: [String], region: Region) async throws {
        guard let userId = userProfile?.id else { throw AuthError.userNotFound }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "fashionInterests": fashionInterests,
                "region": region,
                "profileCompleted": true
            ])
            
            // Refresh user profile
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let userData = try? userDoc.data(as: UserProfile.self) {
                userProfile = userData
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func updateFashionInterests(_ interests: [String]) async throws {
        try await updateProfile(updates: ["fashionInterests": interests])
    }
    
    func updateRegion(_ region: Region) async throws {
        try await updateProfile(updates: ["region": region])
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case userNotFound
    case missingGoogleClientID
    case missingGoogleToken
    case presentationError
    case missingInstagramConfig
    case invalidInstagramURL
    case instagramAuthNotImplemented
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .missingGoogleClientID:
            return "Google Sign In Client ID not found"
        case .missingGoogleToken:
            return "Google Sign In token not found"
        case .presentationError:
            return "Could not present authentication"
        case .missingInstagramConfig:
            return "Instagram configuration not found"
        case .invalidInstagramURL:
            return "Invalid Instagram authentication URL"
        case .instagramAuthNotImplemented:
            return "Instagram authentication not yet implemented"
        }
    }
}

// Add more authentication-related view model functionality as needed 