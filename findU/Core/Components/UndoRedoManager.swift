import Foundation
import Combine

struct UndoableAction {
    let execute: () -> Void
    let undo: () -> Void
    let description: String
}

class UndoRedoManager: ObservableObject {
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false
    @Published private(set) var lastActionDescription: String?
    
    private var undoStack: [UndoableAction] = []
    private var redoStack: [UndoableAction] = []
    private let maxHistorySize: Int
    
    init(maxHistorySize: Int = 50) {
        self.maxHistorySize = maxHistorySize
    }
    
    func perform(_ action: UndoableAction) {
        // Clear redo stack when new action is performed
        redoStack.removeAll()
        
        // Execute the action
        action.execute()
        
        // Add to undo stack
        undoStack.append(action)
        
        // Trim history if needed
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
        
        updateState(lastAction: action)
    }
    
    func undo() {
        guard let action = undoStack.popLast() else { return }
        
        // Execute undo
        action.undo()
        
        // Add to redo stack
        redoStack.append(action)
        
        updateState(lastAction: action)
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        
        // Execute redo
        action.execute()
        
        // Add back to undo stack
        undoStack.append(action)
        
        updateState(lastAction: action)
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState(lastAction: nil)
    }
    
    private func updateState(lastAction: UndoableAction?) {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        lastActionDescription = lastAction?.description
    }
}

// MARK: - Convenience Methods

extension UndoRedoManager {
    func performBatch(_ actions: [UndoableAction], description: String) {
        let batchAction = UndoableAction(
            execute: {
                actions.forEach { $0.execute() }
            },
            undo: {
                actions.reversed().forEach { $0.undo() }
            },
            description: description
        )
        
        perform(batchAction)
    }
    
    func performGroup(_ description: String, _ block: () -> [UndoableAction]) {
        let actions = block()
        performBatch(actions, description: description)
    }
}

// MARK: - Action Builders

extension UndoRedoManager {
    func makeValueChangeAction<T: Equatable>(
        description: String,
        oldValue: T,
        newValue: T,
        set: @escaping (T) -> Void
    ) -> UndoableAction {
        UndoableAction(
            execute: { set(newValue) },
            undo: { set(oldValue) },
            description: description
        )
    }
    
    func makeCollectionChangeAction<T>(
        description: String,
        collection: inout [T],
        change: CollectionChange<T>
    ) -> UndoableAction {
        switch change {
        case .insert(let item, let index):
            return UndoableAction(
                execute: { collection.insert(item, at: index) },
                undo: { collection.remove(at: index) },
                description: description
            )
            
        case .remove(let index):
            let item = collection[index]
            return UndoableAction(
                execute: { collection.remove(at: index) },
                undo: { collection.insert(item, at: index) },
                description: description
            )
            
        case .move(let fromIndex, let toIndex):
            return UndoableAction(
                execute: {
                    let item = collection.remove(at: fromIndex)
                    collection.insert(item, at: toIndex)
                },
                undo: {
                    let item = collection.remove(at: toIndex)
                    collection.insert(item, at: fromIndex)
                },
                description: description
            )
            
        case .update(let index, let newItem):
            let oldItem = collection[index]
            return UndoableAction(
                execute: { collection[index] = newItem },
                undo: { collection[index] = oldItem },
                description: description
            )
        }
    }
}

// MARK: - Supporting Types

enum CollectionChange<T> {
    case insert(item: T, index: Int)
    case remove(index: Int)
    case move(fromIndex: Int, toIndex: Int)
    case update(index: Int, newItem: T)
}

// MARK: - Preview

#if DEBUG
class PreviewUndoRedoManager: ObservableObject {
    @Published var text: String = ""
    let undoRedo = UndoRedoManager()
    
    func updateText(_ newText: String) {
        let action = undoRedo.makeValueChangeAction(
            description: "Update text",
            oldValue: text,
            newValue: newText
        ) { [weak self] value in
            self?.text = value
        }
        
        undoRedo.perform(action)
    }
}
#endif 