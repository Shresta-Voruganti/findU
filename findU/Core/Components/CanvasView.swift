import SwiftUI
import NukeUI
import Combine

protocol CanvasItem: Identifiable {
    var id: UUID { get }
    var position: CGPoint { get }
    var size: CGSize { get }
    var rotation: Double { get }
    var opacity: Double { get }
    var zIndex: Int { get }
    var isLocked: Bool { get }
}

struct CanvasAction<Item: CanvasItem> {
    let execute: () -> Void
    let undo: () -> Void
    let description: String
}

class HistoryManager<Item: CanvasItem> {
    private var undoStack: [CanvasAction<Item>] = []
    private var redoStack: [CanvasAction<Item>] = []
    private let maxHistorySize: Int = 50
    
    func addAction(_ action: CanvasAction<Item>) {
        undoStack.append(action)
        redoStack.removeAll()
        
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
        
        action.execute()
    }
    
    func undo() {
        guard let action = undoStack.popLast() else { return }
        redoStack.append(action)
        action.undo()
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        undoStack.append(action)
        action.execute()
    }
    
    func canUndo() -> Bool {
        !undoStack.isEmpty
    }
    
    func canRedo() -> Bool {
        !redoStack.isEmpty
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

protocol CanvasViewModel: ObservableObject {
    associatedtype Item: CanvasItem
    var items: [Item] { get }
    var selectedItem: Item? { get set }
    var canvasSize: CGSize { get }
    var background: CanvasBackground { get }
    var historyManager: HistoryManager<Item> { get }
    
    func moveItem(_ id: UUID, to position: CGPoint)
    func resizeItem(_ id: UUID, to size: CGSize)
    func rotateItem(_ id: UUID, by angle: Double)
    func setItemOpacity(_ id: UUID, to opacity: Double)
    func setItemZIndex(_ id: UUID, to zIndex: Int)
    func toggleItemLock(_ id: UUID)
    func deleteItem(_ id: UUID)
    
    func undo()
    func redo()
    func clearHistory()
}

extension CanvasViewModel {
    func moveItem(_ id: UUID, to position: CGPoint) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let oldPosition = items[index].position
        
        historyManager.addAction(CanvasAction(
            execute: {
                // Implementation should update the item's position
            },
            undo: {
                // Implementation should restore the old position
            },
            description: "Move item"
        ))
    }
    
    func undo() {
        historyManager.undo()
    }
    
    func redo() {
        historyManager.redo()
    }
    
    func clearHistory() {
        historyManager.clear()
    }
}

struct CanvasView<ViewModel: CanvasViewModel, ItemView: View>: View {
    @ObservedObject var viewModel: ViewModel
    let itemViewBuilder: (ViewModel.Item, Bool) -> ItemView
    
    @GestureState private var scale: CGFloat = 1.0
    @State private var steadyStateScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    
    init(viewModel: ViewModel,
         @ViewBuilder itemViewBuilder: @escaping (ViewModel.Item, Bool) -> ItemView) {
        self.viewModel = viewModel
        self.itemViewBuilder = itemViewBuilder
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                canvasBackground
                
                // Items
                ForEach(viewModel.items.sorted(by: { $0.zIndex < $1.zIndex })) { item in
                    itemViewBuilder(item, viewModel.selectedItem?.id == item.id)
                        .opacity(item.opacity)
                        .zIndex(Double(item.zIndex))
                }
            }
            .frame(width: viewModel.canvasSize.width,
                   height: viewModel.canvasSize.height)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 5)
            .scaleEffect(scale * steadyStateScale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .updating($scale) { value, scale, _ in
                            let newScale = value * steadyStateScale
                            if newScale >= minScale && newScale <= maxScale {
                                scale = value
                            }
                        }
                        .onEnded { value in
                            let newScale = value * steadyStateScale
                            steadyStateScale = min(max(newScale, minScale), maxScale)
                        },
                    DragGesture()
                        .onChanged { value in
                            let maxOffset = calculateMaxOffset(for: geometry.size)
                            let newOffset = CGSize(
                                width: offset.width + value.translation.width,
                                height: offset.height + value.translation.height
                            )
                            offset = constrainOffset(newOffset, within: maxOffset)
                        }
                )
            )
        }
    }
    
    private func calculateMaxOffset(for size: CGSize) -> CGSize {
        let scaledCanvasWidth = viewModel.canvasSize.width * scale * steadyStateScale
        let scaledCanvasHeight = viewModel.canvasSize.height * scale * steadyStateScale
        
        let maxHorizontalOffset = max((scaledCanvasWidth - size.width) / 2, 0)
        let maxVerticalOffset = max((scaledCanvasHeight - size.height) / 2, 0)
        
        return CGSize(width: maxHorizontalOffset, height: maxVerticalOffset)
    }
    
    private func constrainOffset(_ offset: CGSize, within maxOffset: CGSize) -> CGSize {
        CGSize(
            width: min(max(offset.width, -maxOffset.width), maxOffset.width),
            height: min(max(offset.height, -maxOffset.height), maxOffset.height)
        )
    }
    
    private var canvasBackground: some View {
        Group {
            switch viewModel.background {
            case .solid(let color):
                color
            case .gradient(let colors, let angle):
                LinearGradient(colors: colors,
                             startPoint: .top,
                             endPoint: .bottom)
                    .rotationEffect(.degrees(angle))
            case .image(let url):
                LazyImage(url: URL(string: url)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(.systemGray6)
                    }
                }
            case .pattern(let type, let colors):
                PatternView(type: type, colors: colors)
            }
        }
    }
}

struct CanvasItemView<Item: CanvasItem>: View {
    let item: Item
    let isSelected: Bool
    let onTap: () -> Void
    let onMove: (CGPoint) -> Void
    let onResize: (CGSize) -> Void
    let onRotate: (Double) -> Void
    let content: AnyView
    
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var rotationAngle: Angle = .zero
    @GestureState private var scale: CGFloat = 1.0
    
    init<Content: View>(
        item: Item,
        isSelected: Bool,
        onTap: @escaping () -> Void,
        onMove: @escaping (CGPoint) -> Void,
        onResize: @escaping (CGSize) -> Void,
        onRotate: @escaping (Double) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.item = item
        self.isSelected = isSelected
        self.onTap = onTap
        self.onMove = onMove
        self.onResize = onResize
        self.onRotate = onRotate
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .frame(width: item.size.width, height: item.size.height)
            .rotationEffect(Angle(degrees: item.rotation))
            .rotationEffect(rotationAngle)
            .scaleEffect(scale)
            .offset(x: item.position.x + dragOffset.width,
                    y: item.position.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        guard !item.isLocked else { return }
                        state = value.translation
                    }
                    .onEnded { value in
                        guard !item.isLocked else { return }
                        let newPosition = CGPoint(
                            x: item.position.x + value.translation.width,
                            y: item.position.y + value.translation.height
                        )
                        onMove(newPosition)
                    }
            )
            .gesture(
                RotationGesture()
                    .updating($rotationAngle) { value, state, _ in
                        guard !item.isLocked else { return }
                        state = value
                    }
                    .onEnded { value in
                        guard !item.isLocked else { return }
                        onRotate(item.rotation + value.degrees)
                    }
            )
            .gesture(
                MagnificationGesture()
                    .updating($scale) { value, state, _ in
                        guard !item.isLocked else { return }
                        state = value
                    }
                    .onEnded { value in
                        guard !item.isLocked else { return }
                        let newSize = CGSize(
                            width: item.size.width * value,
                            height: item.size.height * value
                        )
                        onResize(newSize)
                    }
            )
            .onTapGesture(perform: onTap)
            .overlay(
                isSelected ? RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.accentColor, lineWidth: 2) : nil
            )
    }
}

struct PatternView: View {
    let type: CanvasBackground.PatternType
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geometry in
            switch type {
            case .dots:
                DotsPattern(colors: colors)
            case .stripes:
                StripesPattern(colors: colors)
            case .checks:
                ChecksPattern(colors: colors)
            case .herringbone:
                HerringbonePattern(colors: colors)
            case .none:
                EmptyView()
            }
        }
    }
}

private struct DotsPattern: View {
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geometry in
            let primaryColor = colors.first ?? .gray
            let secondaryColor = colors.count > 1 ? colors[1] : primaryColor.opacity(0.5)
            let dotSize: CGFloat = 10
            let spacing: CGFloat = 20
            
            ZStack {
                primaryColor
                
                Path { path in
                    let rows = Int(geometry.size.height / spacing) + 1
                    let columns = Int(geometry.size.width / spacing) + 1
                    
                    for row in 0...rows {
                        for column in 0...columns {
                            let x = CGFloat(column) * spacing
                            let y = CGFloat(row) * spacing
                            let offset = row % 2 == 0 ? 0 : spacing / 2
                            
                            path.addEllipse(in: CGRect(
                                x: x + offset,
                                y: y,
                                width: dotSize,
                                height: dotSize
                            ))
                        }
                    }
                }
                .fill(secondaryColor)
            }
        }
    }
}

private struct StripesPattern: View {
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geometry in
            let primaryColor = colors.first ?? .gray
            let secondaryColor = colors.count > 1 ? colors[1] : primaryColor.opacity(0.5)
            let stripeWidth: CGFloat = 20
            
            ZStack {
                primaryColor
                
                Path { path in
                    let stripes = Int(geometry.size.width / (stripeWidth * 2)) + 1
                    
                    for stripe in 0...stripes {
                        let x = CGFloat(stripe) * stripeWidth * 2
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
                        path.addLine(to: CGPoint(x: x + stripeWidth, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        path.closeSubpath()
                    }
                }
                .fill(secondaryColor)
            }
        }
    }
}

private struct ChecksPattern: View {
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geometry in
            let primaryColor = colors.first ?? .gray
            let secondaryColor = colors.count > 1 ? colors[1] : primaryColor.opacity(0.5)
            let checkSize: CGFloat = 30
            
            ZStack {
                primaryColor
                
                Path { path in
                    let rows = Int(geometry.size.height / checkSize) + 1
                    let columns = Int(geometry.size.width / checkSize) + 1
                    
                    for row in 0...rows {
                        for column in 0...columns {
                            if (row + column) % 2 == 0 {
                                let x = CGFloat(column) * checkSize
                                let y = CGFloat(row) * checkSize
                                
                                path.addRect(CGRect(
                                    x: x,
                                    y: y,
                                    width: checkSize,
                                    height: checkSize
                                ))
                            }
                        }
                    }
                }
                .fill(secondaryColor)
            }
        }
    }
}

private struct HerringbonePattern: View {
    let colors: [Color]
    
    var body: some View {
        GeometryReader { geometry in
            let primaryColor = colors.first ?? .gray
            let secondaryColor = colors.count > 1 ? colors[1] : primaryColor.opacity(0.5)
            let stripeWidth: CGFloat = 15
            let stripeLength: CGFloat = 40
            
            ZStack {
                primaryColor
                
                Path { path in
                    let rows = Int(geometry.size.height / stripeLength) + 1
                    let columns = Int(geometry.size.width / (stripeWidth * 2)) + 1
                    
                    for row in 0...rows {
                        for column in 0...columns {
                            let x = CGFloat(column) * stripeWidth * 2
                            let y = CGFloat(row) * stripeLength
                            
                            // Forward slash
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + stripeWidth, y: y + stripeLength))
                            path.addLine(to: CGPoint(x: x + stripeWidth * 2, y: y + stripeLength))
                            path.addLine(to: CGPoint(x: x + stripeWidth, y: y))
                            path.closeSubpath()
                            
                            // Back slash
                            path.move(to: CGPoint(x: x + stripeWidth, y: y))
                            path.addLine(to: CGPoint(x: x + stripeWidth * 2, y: y + stripeLength))
                            path.addLine(to: CGPoint(x: x + stripeWidth * 3, y: y + stripeLength))
                            path.addLine(to: CGPoint(x: x + stripeWidth * 2, y: y))
                            path.closeSubpath()
                        }
                    }
                }
                .fill(secondaryColor)
            }
        }
    }
} 