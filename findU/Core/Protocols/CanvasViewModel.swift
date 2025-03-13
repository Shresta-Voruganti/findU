import SwiftUI

protocol CanvasViewModel: ObservableObject {
    associatedtype Item: CanvasItem
    
    var items: [Item] { get set }
    var selectedItem: Item? { get set }
    var canvasSize: CGSize { get }
    var isLoading: Bool { get set }
    var error: Error? { get set }
    var historyManager: HistoryManager<Item> { get }
    
    // Canvas Operations
    func moveItem(_ id: UUID, to position: CGPoint)
    func resizeItem(_ id: UUID, to size: CGSize)
    func rotateItem(_ id: UUID, by angle: Double)
    func setItemOpacity(_ id: UUID, to opacity: Double)
    func setItemZIndex(_ id: UUID, to zIndex: Int)
    func toggleItemLock(_ id: UUID)
    func deleteItem(_ id: UUID)
} 