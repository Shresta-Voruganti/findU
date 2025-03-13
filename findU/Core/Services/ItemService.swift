import Foundation
import FirebaseFirestore
import FirebaseStorage

class ItemService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let cache = NSCache<NSString, NSArray>()
    
    // MARK: - Item Fetching
    
    func fetchItems() async throws -> [Product] {
        // Check cache first
        if let cachedItems = cache.object(forKey: "allItems") as? [Product] {
            return cachedItems
        }
        
        let snapshot = try await db.collection("products")
            .order(by: "dateAdded", descending: true)
            .getDocuments()
        
        let items = try snapshot.documents.compactMap { try $0.data(as: Product.self) }
        cache.setObject(items as NSArray, forKey: "allItems")
        return items
    }
    
    func fetchItems(ids: [String]) async throws -> [Product] {
        guard !ids.isEmpty else { return [] }
        
        let chunks = ids.chunked(into: 10) // Firestore limit
        var items: [Product] = []
        
        for chunk in chunks {
            let snapshot = try await db.collection("products")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            let chunkItems = try snapshot.documents.compactMap { try $0.data(as: Product.self) }
            items.append(contentsOf: chunkItems)
        }
        
        return items
    }
    
    func fetchItems(withTag tag: String) async throws -> [Product] {
        let snapshot = try await db.collection("products")
            .whereField("tags", arrayContains: tag)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Product.self) }
    }
    
    // MARK: - Search
    
    func searchItems(query: String) async throws -> [Product] {
        // In a real app, this would use a search service like Algolia
        // For now, we'll do a simple client-side search
        let items = try await fetchItems()
        
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            (item.subtitle?.localizedCaseInsensitiveContains(query) ?? false) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Tags
    
    func fetchAvailableTags() async throws -> [String] {
        if let cachedTags = cache.object(forKey: "availableTags") as? [String] {
            return cachedTags
        }
        
        let snapshot = try await db.collection("tags").getDocuments()
        let tags = snapshot.documents.compactMap { $0.data()["name"] as? String }
        cache.setObject(tags as NSArray, forKey: "availableTags")
        return tags
    }
    
    // MARK: - Item Management
    
    func createItem(_ item: Product) async throws {
        try await db.collection("products").document(item.id.uuidString)
            .setData(from: item)
        
        invalidateCache()
    }
    
    func updateItem(_ item: Product) async throws {
        try await db.collection("products").document(item.id.uuidString)
            .setData(from: item, merge: true)
        
        invalidateCache()
    }
    
    func deleteItem(_ id: UUID) async throws {
        try await db.collection("products").document(id.uuidString).delete()
        invalidateCache()
    }
    
    // MARK: - Cache Management
    
    private func invalidateCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Helper Extensions

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Preview

#if DEBUG
extension ItemService {
    static func preview() -> ItemService {
        let service = ItemService()
        // Add sample data if needed
        return service
    }
} 