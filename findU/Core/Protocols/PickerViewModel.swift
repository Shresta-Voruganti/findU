import SwiftUI
import Combine
import Foundation

protocol PickerViewModel: ObservableObject {
    associatedtype Item: PickerItem
    
    // Data
    var items: [Item] { get }
    var recentItems: [Item] { get }
    var favoriteItems: [Item] { get }
    var selectedItems: Set<UUID> { get set }
    
    // UI State
    var searchText: String { get set }
    var isLoading: Bool { get }
    var error: Error? { get }
    
    // Filtering
    var availableTags: [String] { get }
    var selectedTags: Set<String> { get set }
    
    // Loading
    func loadItems() async throws
    func loadRecentItems() async throws
    func loadFavoriteItems() async throws
    
    // Actions
    func toggleFavorite(_ id: UUID)
    func selectItem(_ id: UUID)
    func deselectItem(_ id: UUID)
    func addToRecent(_ id: UUID)
    
    // Search
    func searchItems(query: String) async throws -> [Item]
}

// MARK: - Default Implementation

extension PickerViewModel {
    var selectedItems: Set<UUID> { [] }
    var searchText: String { "" }
    var isLoading: Bool { false }
    var error: Error? { nil }
    var availableTags: [String] { [] }
    var selectedTags: Set<String> { [] }
    
    func toggleFavorite(_ id: UUID) {}
    func selectItem(_ id: UUID) {}
    func deselectItem(_ id: UUID) {}
    func addToRecent(_ id: UUID) {}
    
    func searchItems(query: String) async throws -> [Item] { [] }
} 