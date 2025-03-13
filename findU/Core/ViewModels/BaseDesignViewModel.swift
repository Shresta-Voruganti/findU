import SwiftUI
import Combine

class BaseDesignViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var canvas: DesignCanvas
    @Published var selectedItem: DesignItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Canvas State
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    
    // History State
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    
    // MARK: - Protected Properties
    var history: DesignHistory
    var subscriptions = Set<AnyCancellable>()
    let designService: DesignService
    
    // MARK: - Initialization
    init(designService: DesignService = DesignService()) {
        self.designService = designService
        self.canvas = DesignCanvas(name: "Untitled Design")
        self.history = DesignHistory()
        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        $canvas
            .dropFirst()
            .sink { [weak self] canvas in
                self?.history.recordChange(canvas)
                self?.updateHistoryState()
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Canvas Operations
    func addItem(_ item: DesignItem) {
        canvas.items.append(item)
        selectedItem = item
    }
    
    func removeItem(_ item: DesignItem) {
        canvas.items.removeAll { $0.id == item.id }
        if selectedItem?.id == item.id {
            selectedItem = nil
        }
    }
    
    func updateItemPosition(_ id: UUID, to position: CGPoint) {
        guard let index = canvas.items.firstIndex(where: { $0.id == id }) else { return }
        canvas.items[index].position = position
    }
    
    func updateItemSize(_ id: UUID, to size: CGSize) {
        guard let index = canvas.items.firstIndex(where: { $0.id == id }) else { return }
        canvas.items[index].size = size
    }
    
    func updateItemRotation(_ id: UUID, to angle: Double) {
        guard let index = canvas.items.firstIndex(where: { $0.id == id }) else { return }
        canvas.items[index].rotation = angle
    }
    
    func changeItemOpacity(_ id: UUID, to opacity: Double) {
        guard let index = canvas.items.firstIndex(where: { $0.id == id }) else { return }
        canvas.items[index].opacity = opacity
    }
    
    func toggleItemLock(_ id: UUID) {
        guard let index = canvas.items.firstIndex(where: { $0.id == id }) else { return }
        canvas.items[index].isLocked.toggle()
    }
    
    func changeItemZIndex(_ id: UUID, to zIndex: Int) {
        guard let index = canvas.items.firstIndex(where: { $0.id == id }),
              zIndex >= 0 && zIndex < canvas.items.count else { return }
        canvas.items[index].zIndex = zIndex
        canvas.items.sort { $0.zIndex < $1.zIndex }
    }
    
    // MARK: - Background Operations
    func setBackground(_ background: CanvasBackground) {
        canvas.background = background
    }
    
    // MARK: - History Operations
    func undo() {
        guard let previousCanvas = history.undo() else { return }
        canvas = previousCanvas
        updateHistoryState()
    }
    
    func redo() {
        guard let nextCanvas = history.redo() else { return }
        canvas = nextCanvas
        updateHistoryState()
    }
    
    private func updateHistoryState() {
        canUndo = history.canUndo
        canRedo = history.canRedo
    }
    
    // MARK: - Save & Export
    @discardableResult
    func saveDesign() async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        return try await designService.saveDesign(canvas)
    }
    
    func exportDesign() -> UIImage? {
        // Base implementation for rendering canvas to image
        return nil
    }
} 