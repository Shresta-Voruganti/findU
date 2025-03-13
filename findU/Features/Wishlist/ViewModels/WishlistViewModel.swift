import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

@MainActor
class WishlistViewModel: ObservableObject {
    @Published var collections: [WishlistCollection] = []
    @Published var selectedCollection: WishlistCollection?
    @Published var items: [WishlistItem] = []
    @Published var stats: WishlistStats?
    @Published var isLoading = false
    @Published var error: Error?
    
    // Filtering and Sorting
    @Published var selectedStatus: WishlistItem.Status?
    @Published var selectedPriority: WishlistItem.Priority?
    @Published var sortOption: SortOption = .dateAdded
    
    @Published var searchQuery = ""
    @Published var filteredItems: [WishlistItem] = []
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    enum SortOption: String {
        case dateAdded, priority, price, name
    }
    
    // MARK: - Collection Management
    
    func loadWishlist() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "WishlistError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await db.collection("wishlistCollections")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        collections = try snapshot.documents.map { doc -> WishlistCollection in
            let data = doc.data()
            return try Firestore.Decoder().decode(WishlistCollection.self, from: data)
        }
        
        // Load items for selected collection
        if let selectedCollection = selectedCollection {
            try await loadItems(for: selectedCollection)
        }
        
        try await updateStats()
    }
    
    func createCollection(name: String, description: String?, isPrivate: Bool) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }
        
        let collection = WishlistCollection(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            description: description,
            items: [],
            isPrivate: isPrivate,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await db.collection("wishlistCollections").document(collection.id).setData(from: collection)
        collections.append(collection)
    }
    
    func deleteCollection(_ collection: WishlistCollection) async throws {
        // Delete all items in the collection
        let snapshot = try await db.collection("wishlistItems")
            .whereField("collectionId", isEqualTo: collection.id)
            .getDocuments()
        
        for document in snapshot.documents {
            let item = try Firestore.Decoder().decode(WishlistItem.self, from: document.data())
            if let imageUrl = item.imageUrl {
                // Delete item image from storage
                let storageRef = storage.reference(forURL: imageUrl)
                try await storageRef.delete()
            }
            try await document.reference.delete()
        }
        
        // Delete the collection
        try await db.collection("wishlistCollections").document(collection.id).delete()
        
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections.remove(at: index)
        }
        
        if selectedCollection?.id == collection.id {
            selectedCollection = collections.first
        }
    }
    
    func updateCollection(_ collection: WishlistCollection, name: String, description: String?, isPrivate: Bool) async throws {
        var updatedCollection = collection
        updatedCollection.name = name
        updatedCollection.description = description
        updatedCollection.isPrivate = isPrivate
        updatedCollection.updatedAt = Date()
        
        try await db.collection("wishlistCollections").document(collection.id).setData(from: updatedCollection)
        
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = updatedCollection
        }
        
        if selectedCollection?.id == collection.id {
            selectedCollection = updatedCollection
        }
    }
    
    // MARK: - Item Management
    
    func loadItems(for collection: WishlistCollection) async throws {
        let snapshot = try await db.collection("wishlistItems")
            .whereField("collectionId", isEqualTo: collection.id)
            .getDocuments()
        
        var loadedItems = try snapshot.documents.map { doc -> WishlistItem in
            let data = doc.data()
            return try Firestore.Decoder().decode(WishlistItem.self, from: data)
        }
        
        // Apply filters
        if let status = selectedStatus {
            loadedItems = loadedItems.filter { $0.status == status }
        }
        if let priority = selectedPriority {
            loadedItems = loadedItems.filter { $0.priority == priority }
        }
        
        // Apply sorting
        loadedItems.sort { item1, item2 in
            switch sortOption {
            case .dateAdded:
                return item1.addedAt > item2.addedAt
            case .priority:
                return item1.priority.rawValue > item2.priority.rawValue
            case .price:
                return (item1.price ?? 0) < (item2.price ?? 0)
            case .name:
                return item1.note ?? "" < item2.note ?? ""
            }
        }
        
        items = loadedItems
    }
    
    func addToWishlist(note: String, price: Double?, priority: WishlistItem.Priority) async throws {
        guard let collectionId = selectedCollection?.id else { throw WishlistError.noCollectionSelected }
        guard let userId = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }
        
        let item = WishlistItem(
            id: UUID().uuidString,
            userId: userId,
            collectionId: collectionId,
            note: note,
            price: price,
            priority: priority,
            status: .active,
            addedAt: Date(),
            updatedAt: Date()
        )
        
        try await db.collection("wishlistItems").document(item.id).setData(from: item)
        items.append(item)
        try await updateStats()
    }
    
    func removeFromWishlist(_ item: WishlistItem) async throws {
        try await db.collection("wishlistItems").document(item.id).delete()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
        try await updateStats()
    }
    
    // MARK: - Item Updates
    
    func updateItemStatus(_ item: WishlistItem, status: WishlistItem.Status) async throws {
        try await updateItem(item.id) {
            $0.status = status
            $0.updatedAt = Date()
        }
    }
    
    func updateItemPriority(_ item: WishlistItem, priority: WishlistItem.Priority) async throws {
        try await updateItem(item.id) {
            $0.priority = priority
            $0.updatedAt = Date()
        }
    }
    
    func updateItemNote(_ item: WishlistItem, note: String) async throws {
        try await updateItem(item.id) {
            $0.note = note
            $0.updatedAt = Date()
        }
    }
    
    func updateNotificationSettings(_ item: WishlistItem, enabled: Bool) async throws {
        try await updateItem(item.id) {
            $0.notificationEnabled = enabled
            $0.updatedAt = Date()
        }
    }
    
    func updatePriceAlertThreshold(_ item: WishlistItem, threshold: Double) async throws {
        try await updateItem(item.id) {
            $0.priceAlert = PriceAlert(threshold: threshold, lastChecked: Date())
            $0.updatedAt = Date()
        }
    }
    
    // MARK: - Image Management
    
    func uploadItemImage(_ item: WishlistItem, image: PhotosPickerItem) async throws {
        guard let data = try await image.loadTransferable(type: Data.self) else {
            throw WishlistError.imageUploadFailed
        }
        
        let storageRef = storage.reference().child("wishlist_images/\(item.id).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let url = try await storageRef.downloadURL()
        
        try await updateItem(item.id) {
            $0.imageUrl = url.absoluteString
            $0.updatedAt = Date()
        }
    }
    
    // MARK: - Price Tracking
    
    func updatePrice(_ item: WishlistItem, newPrice: Double) async throws {
        let priceRecord = PriceRecord(date: Date(), price: newPrice)
        
        try await updateItem(item.id) {
            $0.price = newPrice
            $0.priceHistory = ($0.priceHistory ?? []) + [priceRecord]
            $0.updatedAt = Date()
            
            // Check if price alert should be triggered
            if let alert = $0.priceAlert,
               $0.notificationEnabled,
               let oldPrice = $0.price {
                let threshold = oldPrice * (1 - alert.threshold / 100)
                if newPrice <= threshold {
                    // TODO: Trigger price drop notification
                }
            }
        }
    }
    
    // MARK: - Statistics
    
    private func updateStats() async throws {
        guard let collectionId = selectedCollection?.id else { return }
        
        let snapshot = try await db.collection("wishlistItems")
            .whereField("collectionId", isEqualTo: collectionId)
            .getDocuments()
        
        let items = try snapshot.documents.map { doc -> WishlistItem in
            let data = doc.data()
            return try Firestore.Decoder().decode(WishlistItem.self, from: data)
        }
        
        let totalItems = items.count
        let purchasedItems = items.filter { $0.status == .purchased }.count
        let totalValue = items.compactMap { $0.price }.reduce(0, +)
        
        stats = WishlistStats(
            totalItems: totalItems,
            purchasedItems: purchasedItems,
            totalValue: totalValue,
            collectionsCount: collections.count
        )
    }
    
    // MARK: - Helpers
    
    private func updateItem(_ itemId: String, updates: (inout WishlistItem) -> Void) async throws {
        guard var item = items.first(where: { $0.id == itemId }) else {
            throw WishlistError.itemNotFound
        }
        
        updates(&item)
        
        try await db.collection("wishlistItems").document(itemId).setData(from: item)
        
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index] = item
        }
    }
    
    // MARK: - Search and Filter
    
    func searchItems(_ query: String) {
        guard !query.isEmpty else {
            filteredItems = items
            return
        }
        
        filteredItems = items.filter { item in
            let noteMatch = item.note?.localizedCaseInsensitiveContains(query) ?? false
            let priceString = item.price.map { String(format: "%.2f", $0) } ?? ""
            let priceMatch = priceString.contains(query)
            return noteMatch || priceMatch
        }
    }
    
    // MARK: - Sharing
    
    func shareCollection(_ collection: WishlistCollection, withUserId userId: String) async throws {
        let share = CollectionShare(
            id: UUID().uuidString,
            collectionId: collection.id,
            ownerId: collection.userId,
            sharedWithId: userId,
            permissions: .readOnly,
            createdAt: Date()
        )
        
        try await db.collection("collectionShares").document(share.id).setData(from: share)
    }
    
    func updateSharePermissions(_ share: CollectionShare, permissions: SharePermissions) async throws {
        var updatedShare = share
        updatedShare.permissions = permissions
        try await db.collection("collectionShares").document(share.id).setData(from: updatedShare)
    }
    
    func removeShare(_ share: CollectionShare) async throws {
        try await db.collection("collectionShares").document(share.id).delete()
    }
    
    // MARK: - Offline Support
    
    func enableOfflineSupport() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreSettings.CACHE_SIZE_UNLIMITED
        db.settings = settings
    }
    
    func handleConnectionStateChange() {
        Database.database().reference(".info/connected").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            if snapshot.value as? Bool == true {
                // Online - sync pending changes
                Task {
                    try await self.syncPendingChanges()
                }
            }
        }
    }
    
    private func syncPendingChanges() async throws {
        // Implement pending changes sync logic
    }
}

// MARK: - Errors

enum WishlistError: LocalizedError {
    case noCollectionSelected
    case itemNotFound
    case imageUploadFailed
    
    var errorDescription: String? {
        switch self {
        case .noCollectionSelected:
            return "No collection selected"
        case .itemNotFound:
            return "Item not found"
        case .imageUploadFailed:
            return "Failed to upload image"
        }
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        }
    }
}

// MARK: - Additional Models

enum SharePermissions: String, Codable {
    case readOnly
    case readWrite
}

struct CollectionShare: Identifiable, Codable {
    let id: String
    let collectionId: String
    let ownerId: String
    let sharedWithId: String
    var permissions: SharePermissions
    let createdAt: Date
} 