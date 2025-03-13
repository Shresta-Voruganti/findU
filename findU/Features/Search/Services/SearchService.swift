import Foundation
import CoreData
import Vision

class SearchService {
    static let shared = SearchService()
    
    private let networkService = NetworkService.shared
    private let storageService = StorageService.shared
    private let imageSearchService = ImageSearchService.shared
    
    private init() {}
    
    // MARK: - Text Search
    func search(query: String,
               filters: SearchFilters,
               page: Int = 1,
               pageSize: Int = 20) async throws -> SearchResults {
        
        var parameters: [String: Any] = [
            "query": query,
            "page": page,
            "pageSize": pageSize
        ]
        
        // Add filters to parameters
        if let category = filters.category {
            parameters["category"] = category.rawValue
        }
        
        if let priceRange = filters.priceRange {
            parameters["minPrice"] = priceRange.lowerBound
            parameters["maxPrice"] = priceRange.upperBound
        }
        
        if !filters.brands.isEmpty {
            parameters["brands"] = Array(filters.brands)
        }
        
        parameters["sortBy"] = filters.sortBy.rawValue
        parameters["onlyInStock"] = filters.onlyInStock
        
        // Make API request
        let endpoint = "/search"
        return try await withCheckedThrowingContinuation { continuation in
            networkService.get(endpoint, parameters: parameters)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { (results: SearchResults) in
                        continuation.resume(returning: results)
                    }
                )
        }
    }
    
    // MARK: - Combined Search
    func searchWithImage(image: Data,
                        textQuery: String? = nil,
                        filters: SearchFilters) async throws -> SearchResults {
        // First, process the image to extract features
        let imageFeatures = try await imageSearchService.extractImageFeatures(from: image)
        
        // Combine with text search if provided
        var parameters: [String: Any] = [
            "imageFeatures": imageFeatures,
            "useImageSearch": true
        ]
        
        if let textQuery = textQuery {
            parameters["query"] = textQuery
        }
        
        // Add filters
        if let category = filters.category {
            parameters["category"] = category.rawValue
        }
        
        if let priceRange = filters.priceRange {
            parameters["minPrice"] = priceRange.lowerBound
            parameters["maxPrice"] = priceRange.upperBound
        }
        
        // Make API request
        let endpoint = "/search/combined"
        return try await withCheckedThrowingContinuation { continuation in
            networkService.post(endpoint, parameters: parameters)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { (results: SearchResults) in
                        continuation.resume(returning: results)
                    }
                )
        }
    }
    
    // MARK: - Search History
    func saveSearchQuery(_ query: String) {
        Task {
            do {
                var history = try storageService.loadCodableObject(forKey: "searchHistory") as [String]? ?? []
                history.insert(query, at: 0)
                history = Array(history.prefix(10)) // Keep only last 10 searches
                try storageService.saveCodableObject(history, forKey: "searchHistory")
            } catch {
                print("Error saving search history: \(error)")
            }
        }
    }
    
    func getSearchHistory() -> [String] {
        do {
            return try storageService.loadCodableObject(forKey: "searchHistory") as [String]? ?? []
        } catch {
            print("Error loading search history: \(error)")
            return []
        }
    }
    
    func clearSearchHistory() {
        storageService.removeValue(forKey: "searchHistory")
    }
}

// MARK: - Supporting Types
struct SearchResults {
    let items: [SearchResult]
    let hasMore: Bool
    let totalCount: Int
}

extension SearchResults: Codable {
    enum CodingKeys: String, CodingKey {
        case items
        case hasMore = "has_more"
        case totalCount = "total_count"
    }
} 