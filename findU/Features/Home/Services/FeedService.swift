import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class FeedService: FeedServiceProtocol {
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private let feedUpdatesSubject = PassthroughSubject<FeedUpdate, Never>()
    private var listeners: [ListenerRegistration] = []
    private let pageSize = 20
    
    var feedUpdates: AnyPublisher<FeedUpdate, Never> {
        feedUpdatesSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        setupListeners()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    // MARK: - Public Methods
    
    func fetchForYouFeed(filter: FeedFilter, startAfter: QueryDocumentSnapshot?) async throws -> ([FeedItem], QueryDocumentSnapshot?) {
        var query = db.collection("feed_items")
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        query = applyFilter(filter, to: query)
        
        let snapshot = try await query.getDocuments()
        let items = try snapshot.documents.map { try $0.data(as: FeedItem.self) }
        return (items, snapshot.documents.last)
    }
    
    func fetchFollowingFeed(filter: FeedFilter, startAfter: QueryDocumentSnapshot?) async throws -> ([FeedItem], QueryDocumentSnapshot?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.userNotAuthenticated
        }
        
        // Get user's following list
        let followingDoc = try await db.collection("users")
            .document(userId)
            .collection("following")
            .getDocuments()
        
        let followingIds = followingDoc.documents.map { $0.documentID }
        guard !followingIds.isEmpty else {
            return ([], nil)
        }
        
        var query = db.collection("feed_items")
            .whereField("userId", in: followingIds)
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        query = applyFilter(filter, to: query)
        
        let snapshot = try await query.getDocuments()
        let items = try snapshot.documents.map { try $0.data(as: FeedItem.self) }
        return (items, snapshot.documents.last)
    }
    
    func fetchTrendingFeed(filter: FeedFilter, startAfter: QueryDocumentSnapshot?) async throws -> ([FeedItem], QueryDocumentSnapshot?) {
        var query = db.collection("feed_items")
            .order(by: "stats.likes", descending: true)
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        query = applyFilter(filter, to: query)
        
        let snapshot = try await query.getDocuments()
        let items = try snapshot.documents.map { try $0.data(as: FeedItem.self) }
        return (items, snapshot.documents.last)
    }
    
    func likeFeedItem(_ id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.userNotAuthenticated
        }
        
        let itemRef = db.collection("feed_items").document(id)
        let likeRef = itemRef.collection("likes").document(userId)
        
        try await db.runTransaction { transaction, _ in
            let itemDoc = try transaction.getDocument(itemRef)
            guard var item = try? itemDoc.data(as: FeedItem.self) else {
                throw FeedError.itemNotFound
            }
            
            let likeDoc = try transaction.getDocument(likeRef)
            
            if likeDoc.exists {
                // Unlike
                try transaction.deleteDocument(likeRef)
                item.stats.likes -= 1
            } else {
                // Like
                try transaction.setData([:], forDocument: likeRef)
                item.stats.likes += 1
                
                // Create notification for the item owner
                if item.userId != userId {
                    let notification = FeedNotification(
                        id: UUID().uuidString,
                        type: .like,
                        userId: userId,
                        username: "", // Fetch from UserService
                        userAvatarUrl: "", // Fetch from UserService
                        itemId: id,
                        message: "liked your post",
                        timestamp: Date(),
                        isRead: false
                    )
                    
                    try transaction.setData(from: notification, forDocument: db.collection("users")
                        .document(item.userId)
                        .collection("notifications")
                        .document(notification.id))
                }
            }
            
            try transaction.setData(from: item, forDocument: itemRef)
            return nil
        }
    }
    
    func shareFeedItem(_ id: String) async throws {
        let itemRef = db.collection("feed_items").document(id)
        
        try await db.runTransaction { transaction, _ in
            let doc = try transaction.getDocument(itemRef)
            guard var item = try? doc.data(as: FeedItem.self) else {
                throw FeedError.itemNotFound
            }
            
            item.stats.shares += 1
            try transaction.setData(from: item, forDocument: itemRef)
            return nil
        }
    }
    
    func saveFeedItem(_ id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.userNotAuthenticated
        }
        
        let savedRef = db.collection("users")
            .document(userId)
            .collection("saved_items")
            .document(id)
        
        try await savedRef.setData([
            "timestamp": FieldValue.serverTimestamp(),
            "itemId": id
        ])
    }
    
    func deleteFeedItem(_ id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.userNotAuthenticated
        }
        
        let itemRef = db.collection("feed_items").document(id)
        let doc = try await itemRef.getDocument()
        
        guard let item = try? doc.data(as: FeedItem.self),
              item.userId == userId else {
            throw FeedError.unauthorized
        }
        
        // Delete the item and all its related data
        let batch = db.batch()
        
        // Delete likes
        let likes = try await itemRef.collection("likes").getDocuments()
        likes.documents.forEach { batch.deleteDocument($0.reference) }
        
        // Delete comments
        let comments = try await itemRef.collection("comments").getDocuments()
        comments.documents.forEach { batch.deleteDocument($0.reference) }
        
        // Delete the main document
        batch.deleteDocument(itemRef)
        
        try await batch.commit()
    }
    
    func reportFeedItem(_ id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FeedError.userNotAuthenticated
        }
        
        let reportRef = db.collection("reports").document()
        try await reportRef.setData([
            "itemId": id,
            "reporterId": userId,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending"
        ])
    }
    
    // MARK: - Private Methods
    
    private func setupListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Listen for feed updates
        let listener = db.collection("feed_items")
            .whereField("timestamp", isGreaterThan: Date())
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let snapshot = snapshot else { return }
                
                snapshot.documentChanges.forEach { change in
                    guard let item = try? change.document.data(as: FeedItem.self) else { return }
                    
                    let updateType: UpdateType
                    switch change.type {
                    case .added: updateType = .new
                    case .modified: updateType = .modified
                    case .removed: updateType = .deleted
                    }
                    
                    let update = FeedUpdate(type: updateType, item: item)
                    self.feedUpdatesSubject.send(update)
                }
            }
        
        listeners.append(listener)
    }
    
    private func applyFilter(_ filter: FeedFilter, to query: Query) -> Query {
        var filteredQuery = query
        
        // Apply category filter
        if !filter.categories.isEmpty {
            filteredQuery = filteredQuery.whereField("categories", arrayContainsAny: Array(filter.categories))
        }
        
        // Apply price range filter if applicable
        if let priceRange = filter.priceRange {
            filteredQuery = filteredQuery
                .whereField("price", isGreaterThanOrEqualTo: priceRange.lowerBound)
                .whereField("price", isLessThanOrEqualTo: priceRange.upperBound)
        }
        
        // Apply sort option
        switch filter.sortBy {
        case .latest:
            filteredQuery = filteredQuery.order(by: "timestamp", descending: true)
        case .popular:
            filteredQuery = filteredQuery.order(by: "stats.likes", descending: true)
        case .trending:
            // Trending could be a combination of recent activity and popularity
            filteredQuery = filteredQuery
                .order(by: "stats.likes", descending: true)
                .order(by: "timestamp", descending: true)
        }
        
        return filteredQuery
    }
}

// MARK: - Error Types

enum FeedError: LocalizedError {
    case userNotAuthenticated
    case itemNotFound
    case unauthorized
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "You must be signed in to perform this action"
        case .itemNotFound:
            return "The requested item could not be found"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .invalidData:
            return "The data is invalid or corrupted"
        }
    }
} 