import Foundation

protocol PickerItem: Identifiable {
    var id: UUID { get }
    var title: String { get }
    var subtitle: String? { get }
    var imageURL: URL? { get }
    var tags: Set<String> { get }
    var isFavorite: Bool { get }
    var dateAdded: Date { get }
}

// MARK: - Default Implementation

extension PickerItem {
    var subtitle: String? { nil }
    var imageURL: URL? { nil }
    var tags: Set<String> { [] }
    var isFavorite: Bool { false }
    var dateAdded: Date { Date() }
} 