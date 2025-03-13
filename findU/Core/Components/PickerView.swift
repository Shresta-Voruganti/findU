import SwiftUI
import Combine

protocol PickerItem: Identifiable {
    var id: UUID { get }
    var title: String { get }
    var subtitle: String? { get }
    var imageURL: String? { get }
    var isFavorite: Bool { get }
    var tags: Set<String> { get }
    var dateAdded: Date { get }
}

enum PickerSortOption {
    case title
    case dateAdded
    case dateAddedReverse
}

enum PickerFilterOption {
    case all
    case favorites
    case recent
    case tagged(String)
}

protocol PickerViewModel: ObservableObject {
    associatedtype Item: PickerItem
    var items: [Item] { get }
    var recentItems: [Item] { get }
    var favoriteItems: [Item] { get }
    var selectedItem: Item? { get set }
    var isLoading: Bool { get }
    var error: Error? { get }
    var searchText: String { get set }
    var sortOption: PickerSortOption { get set }
    var filterOption: PickerFilterOption { get set }
    var availableTags: Set<String> { get }
    
    func loadItems()
    func loadRecentItems()
    func loadFavoriteItems()
    func toggleFavorite(_ item: Item)
    func selectItem(_ item: Item)
    func searchItems(_ query: String)
    func sortItems(by option: PickerSortOption)
    func filterItems(by option: PickerFilterOption)
}

struct PickerView<ViewModel: PickerViewModel, ItemView: View>: View {
    @ObservedObject var viewModel: ViewModel
    let itemViewBuilder: (ViewModel.Item) -> ItemView
    let columns: [GridItem]
    
    @State private var showingFilterSheet = false
    @State private var showingSortMenu = false
    
    init(viewModel: ViewModel,
         columns: Int = 3,
         @ViewBuilder itemViewBuilder: @escaping (ViewModel.Item) -> ItemView) {
        self.viewModel = viewModel
        self.itemViewBuilder = itemViewBuilder
        self.columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterBar
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    if case .all = viewModel.filterOption {
                        if !viewModel.recentItems.isEmpty {
                            recentItemsSection
                        }
                        
                        if !viewModel.favoriteItems.isEmpty {
                            favoriteItemsSection
                        }
                    }
                    
                    filteredItemsSection
                }
                .padding()
            }
        }
        .overlay(loadingOverlay)
        .alert(error: $viewModel.error)
        .sheet(isPresented: $showingFilterSheet) {
            filterSheet
        }
        .onAppear {
            viewModel.loadItems()
            viewModel.loadRecentItems()
            viewModel.loadFavoriteItems()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: viewModel.searchText) { query in
                    viewModel.searchItems(query)
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                filterButton
                
                sortButton
                
                ForEach(Array(viewModel.availableTags), id: \.self) { tag in
                    tagButton(tag)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var filterButton: some View {
        Button(action: { showingFilterSheet = true }) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("Filter")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
    
    private var sortButton: some View {
        Menu {
            Button("Title") {
                viewModel.sortOption = .title
            }
            Button("Newest First") {
                viewModel.sortOption = .dateAdded
            }
            Button("Oldest First") {
                viewModel.sortOption = .dateAddedReverse
            }
        } label: {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                Text("Sort")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
    
    private func tagButton(_ tag: String) -> some View {
        Button(action: { viewModel.filterOption = .tagged(tag) }) {
            Text(tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    case .tagged(tag) = viewModel.filterOption
                        ? Color.accentColor
                        : Color(.systemBackground)
                )
                .foregroundColor(
                    case .tagged(tag) = viewModel.filterOption
                        ? .white
                        : .primary
                )
                .cornerRadius(8)
        }
    }
    
    private var filterSheet: some View {
        NavigationView {
            List {
                Section(header: Text("View")) {
                    filterOption("All Items", option: .all)
                    filterOption("Favorites", option: .favorites)
                    filterOption("Recent", option: .recent)
                }
                
                Section(header: Text("Tags")) {
                    ForEach(Array(viewModel.availableTags), id: \.self) { tag in
                        filterOption(tag, option: .tagged(tag))
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarItems(trailing: Button("Done") {
                showingFilterSheet = false
            })
        }
    }
    
    private func filterOption(_ title: String, option: PickerFilterOption) -> some View {
        Button(action: {
            viewModel.filterOption = option
            showingFilterSheet = false
        }) {
            HStack {
                Text(title)
                Spacer()
                if viewModel.filterOption == option {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(viewModel.recentItems) { item in
                        itemViewBuilder(item)
                            .frame(width: 100, height: 100)
                            .onTapGesture {
                                viewModel.selectItem(item)
                            }
                    }
                }
            }
        }
    }
    
    private var favoriteItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Favorites")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.favoriteItems) { item in
                    itemViewBuilder(item)
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture {
                            viewModel.selectItem(item)
                        }
                }
            }
        }
    }
    
    private var filteredItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sectionTitle)
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(filteredItems) { item in
                    itemViewBuilder(item)
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture {
                            viewModel.selectItem(item)
                        }
                }
            }
        }
    }
    
    private var sectionTitle: String {
        switch viewModel.filterOption {
        case .all:
            return "All Items"
        case .favorites:
            return "Favorites"
        case .recent:
            return "Recent"
        case .tagged(let tag):
            return tag
        }
    }
    
    private var filteredItems: [ViewModel.Item] {
        var items = viewModel.items
        
        // Apply search filter
        if !viewModel.searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
                (item.subtitle?.localizedCaseInsensitiveContains(viewModel.searchText) ?? false)
            }
        }
        
        // Apply category filter
        switch viewModel.filterOption {
        case .all:
            break
        case .favorites:
            items = items.filter { $0.isFavorite }
        case .recent:
            items = Array(viewModel.recentItems)
        case .tagged(let tag):
            items = items.filter { $0.tags.contains(tag) }
        }
        
        // Apply sort
        switch viewModel.sortOption {
        case .title:
            items.sort { $0.title < $1.title }
        case .dateAdded:
            items.sort { $0.dateAdded > $1.dateAdded }
        case .dateAddedReverse:
            items.sort { $0.dateAdded < $1.dateAdded }
        }
        
        return items
    }
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
}

extension View {
    func alert(error: Binding<Error?>) -> some View {
        let isPresented = Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )
        
        return alert(isPresented: isPresented) {
            Alert(
                title: Text("Error"),
                message: Text(error.wrappedValue?.localizedDescription ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
} 