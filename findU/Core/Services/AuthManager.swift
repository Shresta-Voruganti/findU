import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
    }
    
    var currentUserId: String {
        currentUser?.uid ?? "anonymous"
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.currentUser = result.user
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            await MainActor.run {
                self.currentUser = result.user
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = error
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func updateProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        let changeRequest = user.createProfileChangeRequest()
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        do {
            try await changeRequest.commitChanges()
            await MainActor.run {
                self.currentUser = Auth.auth().currentUser
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        do {
            try await user.delete()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        }
    }
}

// MARK: - Preview

#if DEBUG
extension AuthManager {
    static var preview: AuthManager {
        let manager = AuthManager()
        manager.currentUser = Auth.auth().currentUser
        manager.isAuthenticated = true
        return manager
    }
} 