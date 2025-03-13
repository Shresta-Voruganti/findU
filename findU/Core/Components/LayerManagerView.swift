import SwiftUI

protocol LayerItem: Identifiable {
    var id: UUID { get }
    var title: String { get }
    var type: LayerType { get }
    var isVisible: Bool { get }
    var isLocked: Bool { get }
    var opacity: Double { get }
    var zIndex: Int { get }
}

enum LayerType {
    case image
    case text
    case shape
    case pattern
    
    var icon: String {
        switch self {
        case .image:
            return "photo"
        case .text:
            return "textformat"
        case .shape:
            return "square.on.circle"
        case .pattern:
            return "square.grid.2x2"
        }
    }
}

protocol LayerManagerViewModel: ObservableObject {
    associatedtype Item: LayerItem
    var layers: [Item] { get }
    var selectedLayer: Item? { get set }
    
    func moveLayer(_ indices: IndexSet, to destination: Int)
    func toggleVisibility(for layer: Item)
    func toggleLock(for layer: Item)
    func setOpacity(_ opacity: Double, for layer: Item)
    func deleteLayer(_ layer: Item)
    func duplicateLayer(_ layer: Item)
}

struct LayerManagerView<ViewModel: LayerManagerViewModel>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var draggedLayer: ViewModel.Item?
    @State private var showingOpacityPopover = false
    @State private var selectedLayerForOpacity: ViewModel.Item?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            // Layer List
            List {
                ForEach(viewModel.layers) { layer in
                    layerRow(for: layer)
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
                .onMove { indices, destination in
                    viewModel.moveLayer(indices, to: destination)
                }
            }
            .listStyle(.plain)
        }
        .popover(isPresented: $showingOpacityPopover) {
            if let layer = selectedLayerForOpacity {
                opacityPopover(for: layer)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("Layers")
                .font(.headline)
            
            Spacer()
            
            Button {
                // Add new layer action
            } label: {
                Image(systemName: "plus")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray4)),
            alignment: .bottom
        )
    }
    
    private func layerRow(for layer: ViewModel.Item) -> some View {
        HStack(spacing: 12) {
            // Layer Icon
            Image(systemName: layer.type.icon)
                .foregroundColor(.secondary)
            
            // Layer Title
            Text(layer.title)
                .lineLimit(1)
            
            Spacer()
            
            // Layer Controls
            HStack(spacing: 16) {
                Button {
                    viewModel.toggleVisibility(for: layer)
                } label: {
                    Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                        .foregroundColor(layer.isVisible ? .primary : .secondary)
                }
                
                Button {
                    viewModel.toggleLock(for: layer)
                } label: {
                    Image(systemName: layer.isLocked ? "lock" : "lock.open")
                        .foregroundColor(layer.isLocked ? .primary : .secondary)
                }
                
                Button {
                    selectedLayerForOpacity = layer
                    showingOpacityPopover = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(layer.opacity < 1 ? .primary : .secondary)
                }
                
                Menu {
                    Button(role: .destructive) {
                        viewModel.deleteLayer(layer)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        viewModel.duplicateLayer(layer)
                    } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(viewModel.selectedLayer?.id == layer.id ?
                      Color.accentColor.opacity(0.1) :
                        Color(.systemBackground))
        )
        .onTapGesture {
            viewModel.selectedLayer = layer
        }
    }
    
    private func opacityPopover(for layer: ViewModel.Item) -> some View {
        VStack(spacing: 16) {
            Text("Layer Opacity")
                .font(.headline)
            
            HStack {
                Text("0%")
                Slider(
                    value: Binding(
                        get: { layer.opacity },
                        set: { viewModel.setOpacity($0, for: layer) }
                    ),
                    in: 0...1
                )
                Text("100%")
            }
            .padding()
            
            Button("Done") {
                showingOpacityPopover = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300)
    }
}

struct LayerManagerView_Previews: PreviewProvider {
    class PreviewViewModel: LayerManagerViewModel {
        @Published var layers: [PreviewLayer] = []
        @Published var selectedLayer: PreviewLayer?
        
        init() {
            layers = [
                PreviewLayer(title: "Background", type: .image),
                PreviewLayer(title: "Text Layer", type: .text),
                PreviewLayer(title: "Pattern", type: .pattern)
            ]
        }
        
        func moveLayer(_ indices: IndexSet, to destination: Int) {}
        func toggleVisibility(for layer: PreviewLayer) {}
        func toggleLock(for layer: PreviewLayer) {}
        func setOpacity(_ opacity: Double, for layer: PreviewLayer) {}
        func deleteLayer(_ layer: PreviewLayer) {}
        func duplicateLayer(_ layer: PreviewLayer) {}
    }
    
    struct PreviewLayer: LayerItem {
        let id = UUID()
        let title: String
        let type: LayerType
        var isVisible = true
        var isLocked = false
        var opacity = 1.0
        var zIndex = 0
    }
    
    static var previews: some View {
        LayerManagerView(viewModel: PreviewViewModel())
    }
} 