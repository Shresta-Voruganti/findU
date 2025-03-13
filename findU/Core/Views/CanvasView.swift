import SwiftUI

struct CanvasView<ViewModel: CanvasViewModel, Content: View>: View {
    @ObservedObject var viewModel: ViewModel
    let content: (ViewModel.Item) -> Content
    
    @GestureState private var dragState: DragState?
    @GestureState private var rotationState: RotationState?
    @GestureState private var scaleState: ScaleState?
    
    init(viewModel: ViewModel, @ViewBuilder content: @escaping (ViewModel.Item) -> Content) {
        self.viewModel = viewModel
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Rectangle()
                    .fill(.white)
                    .frame(width: viewModel.canvasSize.width, height: viewModel.canvasSize.height)
                
                // Items
                ForEach(viewModel.items) { item in
                    content(item)
                        .frame(width: item.size.width, height: item.size.height)
                        .position(item.position)
                        .rotationEffect(.degrees(item.rotation))
                        .opacity(item.opacity)
                        .zIndex(Double(item.zIndex))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(viewModel.selectedItem?.id == item.id ? Color.blue : .clear, lineWidth: 2)
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($dragState) { value, state, _ in
                                    state = DragState(
                                        translation: value.translation,
                                        location: value.location,
                                        itemId: item.id
                                    )
                                }
                                .onEnded { value in
                                    guard !item.isLocked else { return }
                                    let newPosition = CGPoint(
                                        x: item.position.x + value.translation.width,
                                        y: item.position.y + value.translation.height
                                    )
                                    viewModel.moveItem(item.id, to: newPosition)
                                }
                        )
                        .gesture(
                            RotationGesture()
                                .updating($rotationState) { value, state, _ in
                                    state = RotationState(
                                        rotation: value,
                                        itemId: item.id
                                    )
                                }
                                .onEnded { value in
                                    guard !item.isLocked else { return }
                                    let newRotation = item.rotation + value.degrees
                                    viewModel.rotateItem(item.id, by: newRotation)
                                }
                        )
                        .gesture(
                            MagnificationGesture()
                                .updating($scaleState) { value, state, _ in
                                    state = ScaleState(
                                        scale: value,
                                        itemId: item.id
                                    )
                                }
                                .onEnded { value in
                                    guard !item.isLocked else { return }
                                    let newSize = CGSize(
                                        width: item.size.width * value,
                                        height: item.size.height * value
                                    )
                                    viewModel.resizeItem(item.id, to: newSize)
                                }
                        )
                        .onTapGesture {
                            viewModel.selectedItem = item
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .scaleEffect(min(
                geometry.size.width / viewModel.canvasSize.width,
                geometry.size.height / viewModel.canvasSize.height
            ))
        }
    }
}

// MARK: - Gesture States

private struct DragState {
    let translation: CGSize
    let location: CGPoint
    let itemId: UUID
}

private struct RotationState {
    let rotation: Angle
    let itemId: UUID
}

private struct ScaleState {
    let scale: CGFloat
    let itemId: UUID
}

// MARK: - Preview

#if DEBUG
struct CanvasView_Previews: PreviewProvider {
    static var previews: some View {
        CanvasView(viewModel: OutfitDesignViewModel.preview()) { item in
            Rectangle()
                .fill(.blue)
        }
    }
} 