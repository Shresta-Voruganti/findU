import SwiftUI

struct PickerView<ViewModel: PickerViewModel, Content: View>: View {
    @ObservedObject var viewModel: ViewModel
    let content: (ViewModel.Item) -> Content
    
    init(viewModel: ViewModel, @ViewBuilder content: @escaping (ViewModel.Item) -> Content) {
        self.viewModel = viewModel
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            searchBar
                .padding()
            
            // Tags
            if !viewModel.availableTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(viewModel.availableTags, id: \.self) { tag in
                            TagButton(
                                title: tag,
                                isSelected: viewModel.selectedTags.contains(tag)
                            ) {
                                if viewModel.selectedTags.contains(tag) {
                                    viewModel.selectedTags.remove(tag)
                                } else {
                                    viewModel.selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            
            // Recent Items
            if !viewModel.recentItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(viewModel.recentItems) { item in
                                content(item)
                                    .frame(width: 100, height: 100)
                                    .onTapGesture {
                                        viewModel.selectItem(item.id)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // All Items
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.items) { item in
                        content(item)
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture {
                                viewModel.selectItem(item.id)
                            }
                    }
                }
                .padding()
            }
        }
        .task {
            do {
                try await viewModel.loadItems()
                try await viewModel.loadRecentItems()
                try await viewModel.loadFavoriteItems()
            } catch {
                print("Error loading items: \(error)")
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PickerView_Previews: PreviewProvider {
    static var previews: some View {
        PickerView(viewModel: MockPickerViewModel()) { item in
            VStack {
                Color.blue
                Text(item.title)
            }
        }
    }
}

private class MockPickerViewModel: PickerViewModel {
    struct MockItem: PickerItem {
        let id = UUID()
        let title: String
        let subtitle: String? = nil
        let tags: Set<String> = []
        let isFavorite = false
        let dateAdded = Date()
    }
    
    @Published var items: [MockItem] = [
        MockItem(title: "Item 1"),
        MockItem(title: "Item 2"),
        MockItem(title: "Item 3")
    ]
    
    @Published var recentItems: [MockItem] = []
    @Published var favoriteItems: [MockItem] = []
    @Published var selectedItems: Set<UUID> = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published var availableTags = ["Tag 1", "Tag 2", "Tag 3"]
    @Published var selectedTags: Set<String> = []
    
    func loadItems() async throws {}
    func loadRecentItems() async throws {}
    func loadFavoriteItems() async throws {}
    func toggleFavorite(_ id: UUID) {}
    func selectItem(_ id: UUID) {}
    func deselectItem(_ id: UUID) {}
    func addToRecent(_ id: UUID) {}
    func searchItems(query: String) async throws -> [MockItem] { [] }
} 