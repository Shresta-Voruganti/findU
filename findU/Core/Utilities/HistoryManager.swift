import Foundation

struct CanvasAction<T> {
    let execute: () -> Void
    let undo: () -> Void
    let description: String
}

class HistoryManager<T> {
    private var undoStack: [CanvasAction<T>] = []
    private var redoStack: [CanvasAction<T>] = []
    private let maxHistorySize: Int
    
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    @Published var lastActionDescription: String?
    
    init(maxHistorySize: Int = 50) {
        self.maxHistorySize = maxHistorySize
    }
    
    func addAction(_ action: CanvasAction<T>) {
        action.execute()
        undoStack.append(action)
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
        updateState()
    }
    
    func undo() {
        guard let action = undoStack.popLast() else { return }
        action.undo()
        redoStack.append(action)
        updateState()
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        action.execute()
        undoStack.append(action)
        updateState()
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState()
    }
    
    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        lastActionDescription = undoStack.last?.description
    }
    
    // MARK: - Batch Operations
    
    func performBatch(_ actions: [CanvasAction<T>], description: String) {
        let batchAction = CanvasAction<T>(
            execute: {
                actions.forEach { $0.execute() }
            },
            undo: {
                actions.reversed().forEach { $0.undo() }
            },
            description: description
        )
        addAction(batchAction)
    }
    
    // MARK: - Action Builders
    
    static func valueChangeAction<V>(
        object: inout V,
        newValue: V,
        description: String
    ) -> CanvasAction<T> {
        let oldValue = object
        return CanvasAction(
            execute: {
                object = newValue
            },
            undo: {
                object = oldValue
            },
            description: description
        )
    }
    
    static func collectionChangeAction<C: RangeReplaceableCollection>(
        collection: inout C,
        change: CollectionChange<C>,
        description: String
    ) -> CanvasAction<T> {
        switch change {
        case .insert(let element, let index):
            return CanvasAction(
                execute: {
                    collection.insert(element, at: index)
                },
                undo: {
                    collection.remove(at: index)
                },
                description: description
            )
            
        case .remove(let index):
            let element = collection[index]
            return CanvasAction(
                execute: {
                    collection.remove(at: index)
                },
                undo: {
                    collection.insert(element, at: index)
                },
                description: description
            )
            
        case .move(let fromIndex, let toIndex):
            return CanvasAction(
                execute: {
                    let element = collection.remove(at: fromIndex)
                    collection.insert(element, at: toIndex)
                },
                undo: {
                    let element = collection.remove(at: toIndex)
                    collection.insert(element, at: fromIndex)
                },
                description: description
            )
            
        case .update(let index, let newElement):
            let oldElement = collection[index]
            return CanvasAction(
                execute: {
                    collection[index] = newElement
                },
                undo: {
                    collection[index] = oldElement
                },
                description: description
            )
        }
    }
}

enum CollectionChange<C: RangeReplaceableCollection> {
    case insert(C.Element, at: C.Index)
    case remove(at: C.Index)
    case move(from: C.Index, to: C.Index)
    case update(at: C.Index, new: C.Element)
}

// MARK: - Preview

#if DEBUG
extension HistoryManager {
    static func preview() -> HistoryManager<Int> {
        let manager = HistoryManager<Int>()
        var value = 0
        
        // Add some sample actions
        manager.addAction(CanvasAction(
            execute: { value += 1 },
            undo: { value -= 1 },
            description: "Increment"
        ))
        
        manager.addAction(CanvasAction(
            execute: { value *= 2 },
            undo: { value /= 2 },
            description: "Double"
        ))
        
        return manager
    }
} 