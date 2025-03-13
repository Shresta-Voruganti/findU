import Foundation

protocol RecentAndFavoriteManageable {
    associatedtype Item: Identifiable
    var userDefaults: UserDefaults { get }
    var recentItemsKey: String { get }
    var favoriteItemsKey: String { get }
    var maxRecentItems: Int { get }
}

extension RecentAndFavoriteManageable {
    var maxRecentItems: Int { 10 }
    
    func loadRecentItemIds() -> [String] {
        userDefaults.array(forKey: recentItemsKey) as? [String] ?? []
    }
    
    func loadFavoriteItemIds() -> [String] {
        userDefaults.array(forKey: favoriteItemsKey) as? [String] ?? []
    }
    
    func addToRecent(_ item: Item) {
        var recentIds = loadRecentItemIds()
        recentIds.removeAll { $0 == item.id.uuidString }
        recentIds.insert(item.id.uuidString, at: 0)
        
        if recentIds.count > maxRecentItems {
            recentIds = Array(recentIds.prefix(maxRecentItems))
        }
        
        userDefaults.set(recentIds, forKey: recentItemsKey)
    }
    
    func toggleFavorite(_ item: Item) {
        var favoriteIds = Set(loadFavoriteItemIds())
        
        if favoriteIds.contains(item.id.uuidString) {
            favoriteIds.remove(item.id.uuidString)
        } else {
            favoriteIds.insert(item.id.uuidString)
        }
        
        userDefaults.set(Array(favoriteIds), forKey: favoriteItemsKey)
    }
    
    func isFavorite(_ item: Item) -> Bool {
        Set(loadFavoriteItemIds()).contains(item.id.uuidString)
    }
} 