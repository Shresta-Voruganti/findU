import Foundation

// MARK: - Social Models

struct SocialPost: Identifiable {
    let id: String
    let userId: String
    var caption: String
    var imageUrls: [String]
    var tags: [String]
    var platform: SocialPlatform
    var stats: SocialStats
    var createdAt: Date
    
    enum SocialPlatform: String, Codable {
        case instagram
        case facebook
        case twitter
    }
}

struct SocialStats {
    var likes: Int
    var comments: Int
    var shares: Int
    var saves: Int
}

struct SocialConnection {
    let platform: SocialPost.SocialPlatform
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let username: String
    let profileUrl: String?
}

struct SocialComment: Identifiable {
    let id: String
    let postId: String
    let userId: String
    let content: String
    let createdAt: Date
    var likes: Int
}

// Add more social-related models as needed 