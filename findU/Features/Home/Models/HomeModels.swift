import Foundation

// MARK: - Home Feed Models

struct FeedItem: Identifiable {
    let id: String
    let type: FeedItemType
    let userId: String
    let username: String
    let userAvatarUrl: String
    let content: Any
    let caption: String?
    let location: String?
    let timestamp: Date
    let stats: FeedItemStats
    var isMine: Bool = false
}

enum FeedItemType {
    case design
    case activity
    case recommendation
    case featured
}

// MARK: - Feed Content Types

struct DesignContent {
    let imageUrl: String
    let tags: [String]
}

struct ActivityContent {
    let title: String
    let description: String
    let imageUrl: String?
    let activityType: ActivityType
    let metadata: [String: Any]
}

struct RecommendationContent {
    let items: [RecommendedItem]
    let reason: String
}

struct FeaturedContent {
    let imageUrl: String
    let title: String
    let description: String
    let callToAction: CallToAction?
}

// MARK: - Supporting Types

struct FeedItemStats {
    let likes: Int
    let comments: Int
    let shares: Int
}

struct RecommendedItem: Identifiable {
    let id: String
    let imageUrl: String
    let title: String
    let price: String
}

struct CallToAction {
    let title: String
    let action: String
    let data: [String: Any]
}

enum ActivityType {
    case newDesign
    case collaboration
    case achievement
    case event
    case sale
}

// MARK: - Feed Actions

enum FeedAction {
    case like
    case comment
    case share
    case save
    case delete
    case edit
    case report
}

// MARK: - Feed Filters

struct FeedFilter {
    var categories: Set<String> = []
    var priceRange: ClosedRange<Double>?
    var sortBy: FeedSortOption = .latest
}

enum FeedSortOption {
    case latest
    case popular
    case trending
}

// MARK: - Notifications

struct FeedNotification: Identifiable {
    let id: String
    let type: NotificationType
    let userId: String
    let username: String
    let userAvatarUrl: String
    let itemId: String?
    let message: String
    let timestamp: Date
    var isRead: Bool
}

enum NotificationType {
    case like
    case comment
    case follow
    case mention
    case designShare
    case achievement
}

// Add more home-related models as needed 