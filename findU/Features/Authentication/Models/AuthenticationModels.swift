import Foundation

// MARK: - Authentication Models

struct UserCredentials {
    let email: String
    let password: String
}

struct UserProfile {
    let id: String
    var username: String
    var email: String
    var profileImageUrl: String?
    var createdAt: Date
    var lastLoginAt: Date?
}

// Add more authentication-related models as needed 