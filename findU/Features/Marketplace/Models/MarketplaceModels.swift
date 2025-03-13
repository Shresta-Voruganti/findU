import Foundation

// MARK: - Marketplace Models

struct Listing: Identifiable {
    let id: String
    let sellerId: String
    var title: String
    var description: String
    var price: Double
    var category: Category
    var condition: Condition
    var images: [String]
    var status: ListingStatus
    var createdAt: Date
    var updatedAt: Date
    var stats: ListingStats
    
    enum Category: String, Codable, CaseIterable {
        case clothing, accessories, shoes, vintage, custom, other
    }
    
    enum Condition: String, Codable, CaseIterable {
        case new, likeNew, good, fair, poor
    }
    
    enum ListingStatus: String, Codable {
        case active, sold, reserved, deleted
    }
}

struct ListingStats {
    var views: Int
    var likes: Int
    var shares: Int
    var saves: Int
}

struct Transaction: Identifiable {
    let id: String
    let listingId: String
    let buyerId: String
    let sellerId: String
    let amount: Double
    let status: TransactionStatus
    let createdAt: Date
    
    enum TransactionStatus: String {
        case pending, completed, cancelled, refunded
    }
}

// Add more marketplace-related models as needed 