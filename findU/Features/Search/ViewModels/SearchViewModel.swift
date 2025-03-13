import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isLoading = false
    @Published var filters = SearchFilters()
    @Published var error: Error?
    
    private var currentPage = 1
    private var hasMoreResults = true
    private var currentSearchTask: Task<Void, Never>?
    private var searchService: SearchService
    private var cancellables = Set<AnyCancellable>()
    
    init(searchService: SearchService = SearchService.shared) {
        self.searchService = searchService
    }
    
    func search(query: String) {
        // Cancel any ongoing search
        currentSearchTask?.cancel()
        
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        currentPage = 1
        isLoading = true
        
        currentSearchTask = Task {
            do {
                let results = try await searchService.search(
                    query: query,
                    filters: filters,
                    page: currentPage
                )
                
                await MainActor.run {
                    self.searchResults = results.items
                    self.hasMoreResults = results.hasMore
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadMoreResults() {
        guard !isLoading && hasMoreResults else { return }
        
        currentPage += 1
        isLoading = true
        
        Task {
            do {
                let results = try await searchService.search(
                    query: searchResults.first?.searchQuery ?? "",
                    filters: filters,
                    page: currentPage
                )
                
                await MainActor.run {
                    self.searchResults.append(contentsOf: results.items)
                    self.hasMoreResults = results.hasMore
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func filterByCategory(_ category: SearchCategory) {
        filters.category = category
        search(query: searchResults.first?.searchQuery ?? "")
    }
    
    func applyFilters(_ newFilters: SearchFilters) {
        filters = newFilters
        search(query: searchResults.first?.searchQuery ?? "")
    }
    
    func clearSearch() {
        searchResults = []
        currentPage = 1
        hasMoreResults = true
        isLoading = false
    }
}

// MARK: - Supporting Types
struct SearchResult: Identifiable, Equatable {
    let id: String
    let searchQuery: String
    let product: Product
    let relevanceScore: Double
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

struct SearchFilters {
    var category: SearchCategory?
    var priceRange: ClosedRange<Double>?
    var brands: Set<String> = []
    var sortBy: SearchSortOption = .relevance
    var onlyInStock = false
}

enum SearchCategory: String, CaseIterable, Identifiable {
    case all
    case clothing
    case shoes
    case accessories
    case beauty
    case home
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .all: return "All"
        case .clothing: return "Clothing"
        case .shoes: return "Shoes"
        case .accessories: return "Accessories"
        case .beauty: return "Beauty"
        case .home: return "Home"
        }
    }
}

enum SearchSortOption: String, CaseIterable {
    case relevance = "Relevance"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    case newest = "Newest"
    case popular = "Popular"
} 