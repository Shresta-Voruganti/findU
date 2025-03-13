import SwiftUI
import Combine

struct BackgroundTemplate: PickerItem {
    let id: UUID
    let title: String
    let subtitle: String?
    let type: BackgroundType
    let tags: Set<String>
    var isFavorite: Bool
    let dateAdded: Date
    
    var imageURL: URL? {
        switch type {
        case .solid(let color):
            return URL(string: "color://\(color.toHex())")
        case .gradient(let colors):
            let hex = colors.map { $0.toHex() }.joined(separator: "-")
            return URL(string: "gradient://\(hex)")
        case .pattern(let url):
            return url
        }
    }
}

class BackgroundPickerViewModel: ObservableObject, PickerViewModel, RecentAndFavoriteManageable {
    typealias Item = BackgroundTemplate
    
    @Published var items: [BackgroundTemplate] = []
    @Published var recentItems: [BackgroundTemplate] = []
    @Published var favoriteItems: [BackgroundTemplate] = []
    @Published var selectedItem: BackgroundTemplate?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var sortOption: PickerSortOption = .dateAdded
    @Published var filterOption: PickerFilterOption = .all
    
    private var cancellables = Set<AnyCancellable>()
    let userDefaults: UserDefaults
    let recentItemsKey = "recentBackgrounds"
    let favoriteItemsKey = "favoriteBackgrounds"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        setupSubscriptions()
        loadDefaultBackgrounds()
    }
    
    private func setupSubscriptions() {
        // Combine search text, sort option, and filter option changes
        Publishers.CombineLatest3($searchText, $sortOption, $filterOption)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.filterAndSortItems()
            }
            .store(in: &cancellables)
    }
    
    private func loadDefaultBackgrounds() {
        // Add solid colors
        items += [
            UIColor.white,
            UIColor.black,
            UIColor.systemGray6,
            UIColor.systemBackground
        ].enumerated().map { index, color in
            BackgroundTemplate(
                id: UUID(),
                title: "Solid Color \(index + 1)",
                subtitle: nil,
                type: .solid(color),
                tags: ["solid", "color"],
                isFavorite: false,
                dateAdded: Date()
            )
        }
        
        // Add gradients
        items += [
            [UIColor.systemBlue, UIColor.systemPurple],
            [UIColor.systemGreen, UIColor.systemYellow],
            [UIColor.systemPink, UIColor.systemOrange]
        ].enumerated().map { index, colors in
            BackgroundTemplate(
                id: UUID(),
                title: "Gradient \(index + 1)",
                subtitle: nil,
                type: .gradient(colors),
                tags: ["gradient"],
                isFavorite: false,
                dateAdded: Date()
            )
        }
        
        // Load pattern backgrounds
        // In a real app, these would be loaded from a server
        items += [
            URL(string: "https://example.com/pattern1.jpg")!,
            URL(string: "https://example.com/pattern2.jpg")!
        ].enumerated().map { index, url in
            BackgroundTemplate(
                id: UUID(),
                title: "Pattern \(index + 1)",
                subtitle: nil,
                type: .pattern(url),
                tags: ["pattern"],
                isFavorite: false,
                dateAdded: Date()
            )
        }
        
        loadRecentItems()
        loadFavoriteItems()
    }
    
    func loadRecentItems() {
        let recentIds = loadRecentItemIds()
        recentItems = items.filter { item in
            recentIds.contains(item.id.uuidString)
        }
    }
    
    func loadFavoriteItems() {
        let favoriteIds = loadFavoriteItemIds()
        favoriteItems = items.filter { item in
            favoriteIds.contains(item.id.uuidString)
        }
        
        // Update isFavorite status for all items
        items = items.map { item in
            var updatedItem = item
            updatedItem.isFavorite = favoriteIds.contains(item.id.uuidString)
            return updatedItem
        }
    }
    
    func selectItem(_ item: BackgroundTemplate) {
        selectedItem = item
        addToRecent(item)
        loadRecentItems()
    }
    
    private func filterAndSortItems() {
        var filteredItems = items
        
        // Apply search filter
        if !searchText.isEmpty {
            filteredItems = filteredItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                (item.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply filter option
        switch filterOption {
        case .all:
            break
        case .favorites:
            filteredItems = filteredItems.filter { $0.isFavorite }
        case .tag(let tag):
            filteredItems = filteredItems.filter { $0.tags.contains(tag) }
        }
        
        // Apply sort option
        switch sortOption {
        case .dateAdded:
            filteredItems.sort { $0.dateAdded > $1.dateAdded }
        case .title:
            filteredItems.sort { $0.title < $1.title }
        }
        
        items = filteredItems
    }
}

// MARK: - Preview

#if DEBUG
extension BackgroundPickerViewModel {
    static func preview() -> BackgroundPickerViewModel {
        let viewModel = BackgroundPickerViewModel()
        viewModel.toggleFavorite(viewModel.items[0])
        viewModel.selectItem(viewModel.items[1])
        return viewModel
    }
} 