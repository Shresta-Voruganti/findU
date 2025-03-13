import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import CoreData

protocol DesignServiceProtocol {
    func saveDesign(_ design: DesignCanvas) async throws
    func loadDesign(id: UUID) async throws -> DesignCanvas
    func deleteDesign(id: UUID) async throws
    func fetchProducts() async throws -> [Product]
    func saveRecentItems(_ items: [Product]) async throws
    func loadRecentItems() async throws -> [Product]
    func saveFavoriteItems(_ itemIds: [UUID]) async throws
    func loadFavoriteItems() async throws -> [UUID]
    func saveRecentBackgrounds(colors: [Color], gradients: [Gradient], images: [UIImage]) async throws
    func loadRecentBackgrounds() async throws -> (colors: [Color], gradients: [Gradient], images: [UIImage])
}

class DesignService: DesignServiceProtocol {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let storageService: StorageService
    private let networkService: NetworkService
    private let coreDataStack: CoreDataStack
    
    @Published var errorMessage: String?
    
    // MARK: - Singleton
    
    static let shared = DesignService()
    
    // MARK: - Initialization
    
    init(
        storageService: StorageService = StorageService.shared,
        networkService: NetworkService = NetworkService.shared,
        coreDataStack: CoreDataStack = CoreDataStack.shared
    ) {
        self.storageService = storageService
        self.networkService = networkService
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Design CRUD Operations
    
    /// Creates a new design
    func createDesign(_ design: Design) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "DesignService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var designData = design
        designData.creatorId = userId
        designData.createdAt = Date()
        designData.updatedAt = Date()
        
        let docRef = try await db.collection("designs").addDocument(from: designData)
        return docRef.documentID
    }
    
    /// Updates an existing design
    func updateDesign(_ design: Design) async throws {
        guard let designId = design.id else { throw NSError(domain: "DesignService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Design ID not found"]) }
        
        var updatedDesign = design
        updatedDesign.updatedAt = Date()
        
        try await db.collection("designs").document(designId).setData(from: updatedDesign)
    }
    
    /// Fetches a design by ID
    func fetchDesign(id: String) async throws -> Design {
        let docRef = db.collection("designs").document(id)
        let document = try await docRef.getDocument()
        
        guard let design = try? document.data(as: Design.self) else {
            throw NSError(domain: "DesignService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Design not found"])
        }
        
        return design
    }
    
    /// Deletes a design
    func deleteDesign(id: UUID) async throws {
        // Delete from local storage
        try await storageService.deleteDesign(id: id)
        
        // Delete from Core Data
        try await deleteFromCoreData(id: id)
        
        // Delete from server
        try await deleteDesignFromServer(id: id)
    }
    
    // MARK: - Image Operations
    
    /// Uploads a design image
    func uploadDesignImage(_ image: UIImage, designId: String, isThumb: Bool = false) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: isThumb ? 0.5 : 0.8) else {
            throw NSError(domain: "DesignService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }
        
        let filename = "\(isThumb ? "thumb" : "full")_\(UUID().uuidString).jpg"
        let path = "designs/\(designId)/\(filename)"
        let imageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await imageRef.downloadURL()
        
        return url.absoluteString
    }
    
    // MARK: - Template Operations
    
    /// Creates a new template
    func createTemplate(_ template: DesignTemplate) async throws -> String {
        let docRef = try await db.collection("designTemplates").addDocument(from: template)
        return docRef.documentID
    }
    
    /// Fetches templates by category
    func fetchTemplates(category: Design.Category? = nil) async throws -> [DesignTemplate] {
        var query: Query = db.collection("designTemplates")
        
        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: DesignTemplate.self) }
    }
    
    // MARK: - Stats Operations
    
    /// Updates design stats
    func updateStats(designId: String, type: StatType) async throws {
        let ref = db.collection("designs").document(designId)
        
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot = try transaction.getDocument(ref)
            guard var design = try? snapshot.data(as: Design.self) else { return nil }
            
            switch type {
            case .view: design.stats.views += 1
            case .like: design.stats.likes += 1
            case .share: design.stats.shares += 1
            case .save: design.stats.saves += 1
            case .comment: design.stats.comments += 1
            }
            
            try transaction.setData(from: design, forDocument: ref)
            return nil
        })
    }
    
    enum StatType {
        case view, like, share, save, comment
    }
    
    // MARK: - Search & Discovery
    
    /// Searches designs by query
    func searchDesigns(query: String, category: Design.Category? = nil) async throws -> [Design] {
        var baseQuery: Query = db.collection("designs")
            .whereField("isPublished", isEqualTo: true)
        
        if let category = category {
            baseQuery = baseQuery.whereField("category", isEqualTo: category.rawValue)
        }
        
        // Search in title, description, and tags
        let snapshot = try await baseQuery.getDocuments()
        let designs = try snapshot.documents.compactMap { try $0.data(as: Design.self) }
        
        return designs.filter { design in
            let searchText = query.lowercased()
            return design.title.lowercased().contains(searchText) ||
                   design.description.lowercased().contains(searchText) ||
                   design.tags.contains { $0.lowercased().contains(searchText) }
        }
    }
    
    /// Fetches trending designs
    func fetchTrendingDesigns(limit: Int = 10) async throws -> [Design] {
        let snapshot = try await db.collection("designs")
            .whereField("isPublished", isEqualTo: true)
            .order(by: "stats.views", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Design.self) }
    }
    
    // MARK: - Product Management
    
    func fetchProducts() async throws -> [Product] {
        // Try to load from cache first
        if let cachedProducts = try? await storageService.loadProducts() {
            return cachedProducts
        }
        
        // Fetch from server
        let products = try await networkService.fetchProducts()
        
        // Cache the results
        try? await storageService.saveProducts(products)
        
        return products
    }
    
    // MARK: - Recent Items Management
    
    func saveRecentItems(_ items: [Product]) async throws {
        try await storageService.saveRecentItems(items)
    }
    
    func loadRecentItems() async throws -> [Product] {
        return try await storageService.loadRecentItems()
    }
    
    // MARK: - Favorite Items Management
    
    func saveFavoriteItems(_ itemIds: [UUID]) async throws {
        try await storageService.saveFavoriteItems(itemIds)
    }
    
    func loadFavoriteItems() async throws -> [UUID] {
        return try await storageService.loadFavoriteItems()
    }
    
    // MARK: - Background Management
    
    func saveRecentBackgrounds(
        colors: [Color],
        gradients: [Gradient],
        images: [UIImage]
    ) async throws {
        try await storageService.saveRecentBackgrounds(
            colors: colors,
            gradients: gradients,
            images: images
        )
    }
    
    func loadRecentBackgrounds() async throws -> (
        colors: [Color],
        gradients: [Gradient],
        images: [UIImage]
    ) {
        return try await storageService.loadRecentBackgrounds()
    }
    
    // MARK: - Core Data Operations
    
    private func saveToCoreData(_ design: DesignCanvas) async throws {
        let context = coreDataStack.backgroundContext
        
        try await context.perform {
            let designEntity = DesignEntity(context: context)
            designEntity.id = design.id
            designEntity.name = design.name
            designEntity.createdAt = design.createdAt
            designEntity.updatedAt = design.updatedAt
            
            // Save background
            let backgroundData = try JSONEncoder().encode(design.background)
            designEntity.backgroundData = backgroundData
            
            // Save items
            let itemsData = try JSONEncoder().encode(design.items)
            designEntity.itemsData = itemsData
            
            try context.save()
        }
    }
    
    private func loadFromCoreData(id: UUID) async throws -> DesignCanvas {
        let context = coreDataStack.backgroundContext
        
        return try await context.perform {
            let request: NSFetchRequest<DesignEntity> = DesignEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            guard let designEntity = try context.fetch(request).first else {
                throw DesignError.notFound
            }
            
            let background = try JSONDecoder().decode(
                CanvasBackground.self,
                from: designEntity.backgroundData ?? Data()
            )
            
            let items = try JSONDecoder().decode(
                [DesignItem].self,
                from: designEntity.itemsData ?? Data()
            )
            
            return DesignCanvas(
                id: designEntity.id ?? UUID(),
                name: designEntity.name ?? "",
                items: items,
                background: background,
                createdAt: designEntity.createdAt ?? Date(),
                updatedAt: designEntity.updatedAt ?? Date()
            )
        }
    }
    
    private func deleteFromCoreData(id: UUID) async throws {
        let context = coreDataStack.backgroundContext
        
        try await context.perform {
            let request: NSFetchRequest<DesignEntity> = DesignEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let designs = try context.fetch(request)
            designs.forEach { context.delete($0) }
            
            try context.save()
        }
    }
    
    // MARK: - Server Operations
    
    private func syncDesign(_ design: DesignCanvas) async throws {
        // Implement server sync logic here
        // This would typically involve making API calls to sync the design with a backend server
    }
    
    private func fetchDesignFromServer(id: UUID) async throws -> DesignCanvas {
        // Implement server fetch logic here
        // This would typically involve making API calls to fetch the design from a backend server
        throw DesignError.notFound
    }
    
    private func deleteDesignFromServer(id: UUID) async throws {
        // Implement server delete logic here
        // This would typically involve making API calls to delete the design from a backend server
    }
}

// MARK: - Errors

enum DesignError: LocalizedError {
    case notFound
    case saveFailed
    case deleteFailed
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Design not found"
        case .saveFailed:
            return "Failed to save design"
        case .deleteFailed:
            return "Failed to delete design"
        case .syncFailed:
            return "Failed to sync design with server"
        }
    }
} 