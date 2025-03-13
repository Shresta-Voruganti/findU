import SwiftUI
import Combine

class ItemPickerViewModel: ObservableObject, PickerViewModel, RecentAndFavoriteManageable {
    typealias Item = Product
    
    @Published var items: [Product] = []
    @Published var recentItems: [Product] = []
    @Published var favoriteItems: [Product] = []
    @Published var selectedItem: Product?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var sortOption: PickerSortOption = .dateAdded
    @Published var filterOption: PickerFilterOption = .all
    
    private(set) var availableTags: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    let userDefaults: UserDefaults
    let recentItemsKey = "recentItems"
    let favoriteItemsKey = "favoriteItems"
    private let itemService: ItemService
    
    init(itemService: ItemService = ItemService(),
         userDefaults: UserDefaults = .standard) {
        self.itemService = itemService
        self.userDefaults = userDefaults
        
        setupSubscriptions()
        loadAvailableTags()
    }
    
    private func setupSubscriptions() {
        // Search text debounce
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchItems(query)
            }
            .store(in: &cancellables)
        
        // Sort option changes
        $sortOption
            .dropFirst()
            .sink { [weak self] option in
                self?.sortItems(by: option)
            }
            .store(in: &cancellables)
        
        // Filter option changes
        $filterOption
            .dropFirst()
            .sink { [weak self] option in
                self?.filterItems(by: option)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadItems() {
        isLoading = true
        
        Task {
            do {
                let loadedItems = try await itemService.fetchItems()
                await MainActor.run {
                    items = loadedItems
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    func loadRecentItems() {
        let recentIds = loadRecentItemIds()
        
        Task {
            do {
                let loadedItems = try await itemService.fetchItems(ids: recentIds)
                await MainActor.run {
                    recentItems = loadedItems
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func loadFavoriteItems() {
        let favoriteIds = loadFavoriteItemIds()
        
        Task {
            do {
                let loadedItems = try await itemService.fetchItems(ids: favoriteIds)
                await MainActor.run {
                    favoriteItems = loadedItems
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    private func loadAvailableTags() {
        Task {
            do {
                let tags = try await itemService.fetchAvailableTags()
                await MainActor.run {
                    availableTags = Set(tags)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Item Management
    
    func toggleFavorite(_ item: Product) {
        var favoriteIds = Set(userDefaults.array(forKey: "favoriteItems") as? [String] ?? [])
        
        if favoriteIds.contains(item.id.uuidString) {
            favoriteIds.remove(item.id.uuidString)
        } else {
            favoriteIds.insert(item.id.uuidString)
        }
        
        userDefaults.set(Array(favoriteIds), forKey: "favoriteItems")
        loadFavoriteItems()
    }
    
    func selectItem(_ item: Product) {
        selectedItem = item
        addToRecent(item)
        loadRecentItems()
    }
    
    // MARK: - Search and Filtering
    
    func searchItems(_ query: String) {
        guard !query.isEmpty else {
            loadItems()
            return
        }
        
        Task {
            do {
                let searchResults = try await itemService.searchItems(query: query)
                await MainActor.run {
                    items = searchResults
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func sortItems(by option: PickerSortOption) {
        switch option {
        case .title:
            items.sort { $0.title < $1.title }
        case .dateAdded:
            items.sort { $0.dateAdded > $1.dateAdded }
        case .dateAddedReverse:
            items.sort { $0.dateAdded < $1.dateAdded }
        }
    }
    
    func filterItems(by option: PickerFilterOption) {
        switch option {
        case .all:
            loadItems()
        case .favorites:
            loadFavoriteItems()
        case .recent:
            loadRecentItems()
        case .tagged(let tag):
            Task {
                do {
                    let filteredItems = try await itemService.fetchItems(withTag: tag)
                    await MainActor.run {
                        items = filteredItems
                    }
                } catch {
                    await MainActor.run {
                        self.error = error
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
extension ItemPickerViewModel {
    static func preview() -> ItemPickerViewModel {
        let viewModel = ItemPickerViewModel()
        
        viewModel.items = [
            Product(id: UUID(),
                   title: "T-Shirt",
                   subtitle: "Cotton Blend",
                   imageURLs: ["sample_tshirt"],
                   tags: ["Tops", "Casual"],
                   isFavorite: true,
                   dateAdded: Date()),
            Product(id: UUID(),
                   title: "Jeans",
                   subtitle: "Slim Fit",
                   imageURLs: ["sample_jeans"],
                   tags: ["Bottoms", "Casual"],
                   isFavorite: false,
                   dateAdded: Date().addingTimeInterval(-86400))
        ]
        
        viewModel.recentItems = Array(viewModel.items.prefix(1))
        viewModel.favoriteItems = viewModel.items.filter { $0.isFavorite }
        viewModel.availableTags = ["Tops", "Bottoms", "Casual", "Formal"]
        
        return viewModel
    }
} 