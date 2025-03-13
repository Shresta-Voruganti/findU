import SwiftUI

struct OutfitDesignView: View {
    @StateObject private var viewModel = DesignViewModel()
    @State private var showingToolbar = true
    @State private var selectedTool: DesignTool = .move
    @State private var showingColorPicker = false
    @State private var showingItemPicker = false
    @State private var showingBackgroundPicker = false
    @State private var showingSaveDialog = false
    
    private let tools: [DesignTool] = [
        .move,
        .addItem,
        .background,
        .layers,
        .undo,
        .redo
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Canvas
                ScrollView([.horizontal, .vertical]) {
                    DesignCanvasView(viewModel: viewModel)
                        .padding()
                }
                
                // Bottom Toolbar
                VStack {
                    Spacer()
                    
                    if showingToolbar {
                        toolbarView
                            .transition(.move(edge: .bottom))
                    }
                }
                
                // Item Properties Panel (when item is selected)
                if let selectedItem = viewModel.selectedItem {
                    itemPropertiesPanel(for: selectedItem)
                        .transition(.move(edge: .trailing))
                }
            }
            .navigationTitle(viewModel.canvas.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingSaveDialog = true }) {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: { viewModel.showSharingOptions = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { showingToolbar.toggle() }) {
                            Label(showingToolbar ? "Hide Toolbar" : "Show Toolbar",
                                  systemImage: showingToolbar ? "chevron.down" : "chevron.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingItemPicker) {
                ItemPickerView(onItemSelected: { product in
                    viewModel.addItem(product)
                    showingItemPicker = false
                })
            }
            .sheet(isPresented: $showingBackgroundPicker) {
                BackgroundPickerView(onBackgroundSelected: { background in
                    viewModel.setBackground(background)
                    showingBackgroundPicker = false
                })
            }
            .sheet(isPresented: $viewModel.showSharingOptions) {
                if let image = viewModel.exportDesign() {
                    ShareSheet(items: [image])
                }
            }
            .alert("Save Design", isPresented: $showingSaveDialog) {
                TextField("Design Name", text: $viewModel.canvas.name)
                Button("Save", action: viewModel.saveDesign)
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private var toolbarView: some View {
        HStack(spacing: 20) {
            ForEach(tools, id: \.self) { tool in
                Button {
                    handleToolTap(tool)
                } label: {
                    Image(systemName: tool.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(selectedTool == tool ? .accentColor : .primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
        .padding()
    }
    
    private func itemPropertiesPanel(for item: DesignItem) -> some View {
        VStack {
            HStack {
                Text("Item Properties")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.selectedItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
            
            VStack(spacing: 16) {
                // Opacity Slider
                VStack(alignment: .leading) {
                    Text("Opacity")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { item.opacity },
                        set: { viewModel.changeItemOpacity(item.id, to: $0) }
                    ), in: 0...1)
                }
                
                // Lock Toggle
                Toggle("Lock Item", isOn: Binding(
                    get: { item.isLocked },
                    set: { _ in viewModel.toggleItemLock(item.id) }
                ))
                
                // Layer Controls
                HStack {
                    Text("Layer")
                        .font(.subheadline)
                    Spacer()
                    Button {
                        viewModel.changeItemZIndex(item.id, to: item.zIndex - 1)
                    } label: {
                        Image(systemName: "arrow.down.circle")
                    }
                    .disabled(item.zIndex <= 0)
                    
                    Button {
                        viewModel.changeItemZIndex(item.id, to: item.zIndex + 1)
                    } label: {
                        Image(systemName: "arrow.up.circle")
                    }
                }
                
                // Delete Button
                Button(role: .destructive) {
                    viewModel.removeSelectedItem()
                } label: {
                    Label("Delete Item", systemImage: "trash")
                }
            }
            .padding()
        }
        .frame(width: 300)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
    
    private func handleToolTap(_ tool: DesignTool) {
        selectedTool = tool
        
        switch tool {
        case .addItem:
            showingItemPicker = true
        case .background:
            showingBackgroundPicker = true
        case .undo:
            viewModel.undo()
        case .redo:
            viewModel.redo()
        default:
            break
        }
    }
}

enum DesignTool: String {
    case move = "Move"
    case addItem = "Add Item"
    case background = "Background"
    case layers = "Layers"
    case undo = "Undo"
    case redo = "Redo"
    
    var iconName: String {
        switch self {
        case .move: return "arrow.up.and.down.and.arrow.left.and.right"
        case .addItem: return "plus.circle"
        case .background: return "photo"
        case .layers: return "square.3.stack.3d"
        case .undo: return "arrow.uturn.backward"
        case .redo: return "arrow.uturn.forward"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Preview
struct OutfitDesignView_Previews: PreviewProvider {
    static var previews: some View {
        OutfitDesignView()
    }
} 