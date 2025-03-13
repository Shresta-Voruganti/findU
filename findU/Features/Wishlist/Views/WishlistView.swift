import SwiftUI

struct WishlistView: View {
    @StateObject private var viewModel = WishlistViewModel()
    @State private var showingAddCollection = false
    @State private var showingAddItem = false
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Collections Picker
                CollectionPickerView(
                    collections: viewModel.collections,
                    selectedCollection: $viewModel.selectedCollection
                )
                
                // Stats Bar
                if let stats = viewModel.stats {
                    WishlistStatsBar(stats: stats)
                }
                
                // Filter Bar
                FilterBar(
                    sortOption: $viewModel.sortOption,
                    showingFilters: $showingFilters
                )
                
                // Main Content
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.items.isEmpty {
                    EmptyWishlistView(showingAddItem: $showingAddItem)
                } else {
                    WishlistItemsGrid(items: viewModel.items) { item in
                        Task {
                            try await viewModel.removeFromWishlist(item)
                        }
                    }
                }
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddItem = true }) {
                            Label("Add Item", systemImage: "plus")
                        }
                        Button(action: { showingAddCollection = true }) {
                            Label("New Collection", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddCollection) {
                AddCollectionSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddItem) {
                AddWishlistItemSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    selectedStatus: $viewModel.selectedStatus,
                    selectedPriority: $viewModel.selectedPriority
                )
            }
            .task {
                await viewModel.loadWishlist()
            }
        }
    }
}

// MARK: - Collection Picker View
struct CollectionPickerView: View {
    let collections: [WishlistCollection]
    @Binding var selectedCollection: WishlistCollection?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(collections) { collection in
                    CollectionButton(
                        collection: collection,
                        isSelected: collection.id == selectedCollection?.id
                    ) {
                        selectedCollection = collection
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
}

struct CollectionButton: View {
    let collection: WishlistCollection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(collection.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if let count = collection.items.count {
                    Text("\(count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stats Bar
struct WishlistStatsBar: View {
    let stats: WishlistStats
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                StatItem(title: "Total", value: "\(stats.totalItems)")
                StatItem(title: "Purchased", value: "\(stats.purchasedItems)")
                StatItem(title: "Value", value: String(format: "$%.2f", stats.totalValue))
                StatItem(title: "Collections", value: "\(stats.collectionsCount)")
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var sortOption: WishlistViewModel.SortOption
    @Binding var showingFilters: Bool
    
    var body: some View {
        HStack {
            Menu {
                ForEach([
                    WishlistViewModel.SortOption.dateAdded,
                    .priority,
                    .price,
                    .name
                ], id: \.self) { option in
                    Button(action: { sortOption = option }) {
                        Label(sortOptionLabel(option), systemImage: sortOptionIcon(option))
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            
            Spacer()
            
            Button(action: { showingFilters = true }) {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
    
    private func sortOptionLabel(_ option: WishlistViewModel.SortOption) -> String {
        switch option {
        case .dateAdded: return "Date Added"
        case .priority: return "Priority"
        case .price: return "Price"
        case .name: return "Name"
        }
    }
    
    private func sortOptionIcon(_ option: WishlistViewModel.SortOption) -> String {
        switch option {
        case .dateAdded: return "calendar"
        case .priority: return "exclamationmark.circle"
        case .price: return "dollarsign.circle"
        case .name: return "textformat"
        }
    }
}

// MARK: - Empty View
struct EmptyWishlistView: View {
    @Binding var showingAddItem: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Your wishlist is empty")
                .font(.headline)
            
            Text("Start adding items you'd like to save for later")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddItem = true }) {
                Label("Add First Item", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Items Grid
struct WishlistItemsGrid: View {
    let items: [WishlistItem]
    let onDelete: (WishlistItem) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    WishlistItemCard(item: item, onDelete: { onDelete(item) }, viewModel: viewModel)
                }
            }
            .padding()
        }
    }
}

struct WishlistItemCard: View {
    let item: WishlistItem
    let onDelete: () -> Void
    @State private var showingDetail = false
    @ObservedObject var viewModel: WishlistViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            AsyncImage(url: URL(string: item.imageUrl ?? "placeholder")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                if let price = item.price {
                    Text(String(format: "$%.2f", price))
                        .font(.headline)
                }
                
                Text(item.note ?? "")
                    .font(.subheadline)
                    .lineLimit(2)
                
                HStack {
                    PriorityBadge(priority: item.priority)
                    Spacer()
                    StatusBadge(status: item.status)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture {
            showingDetail = true
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Remove", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDetail) {
            WishlistItemDetailView(viewModel: viewModel, item: item)
        }
    }
}

// MARK: - Badges
struct PriorityBadge: View {
    let priority: WishlistItem.Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.1))
            .foregroundColor(priorityColor)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct StatusBadge: View {
    let status: WishlistItem.Status
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .active: return .blue
        case .purchased: return .green
        case .unavailable: return .gray
        case .archived: return .secondary
        }
    }
}

// MARK: - Add Collection Sheet
struct AddCollectionSheet: View {
    @ObservedObject var viewModel: WishlistViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isPrivate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                    TextField("Description (Optional)", text: $description)
                }
                
                Section {
                    Toggle("Private Collection", isOn: $isPrivate)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            try await viewModel.createCollection(
                                name: name,
                                description: description,
                                isPrivate: isPrivate
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Item Sheet
struct AddWishlistItemSheet: View {
    @ObservedObject var viewModel: WishlistViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var note = ""
    @State private var price: Double?
    @State private var priority = WishlistItem.Priority.medium
    @State private var enableNotifications = false
    @State private var selectedImage: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Label("Add Image", systemImage: "photo")
                    }
                }
                
                Section {
                    TextField("Note", text: $note)
                    TextField("Price", value: $price, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(WishlistItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized)
                                .tag(priority)
                        }
                    }
                }
                
                Section {
                    Toggle("Price Drop Notifications", isOn: $enableNotifications)
                }
            }
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            try await viewModel.addToWishlist(
                                note: note,
                                price: price,
                                priority: priority
                            )
                            dismiss()
                        }
                    }
                    .disabled(note.isEmpty)
                }
            }
        }
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Binding var selectedStatus: WishlistItem.Status?
    @Binding var selectedPriority: WishlistItem.Priority?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Status") {
                    StatusFilterPicker(selectedStatus: $selectedStatus)
                }
                
                Section("Priority") {
                    PriorityFilterPicker(selectedPriority: $selectedPriority)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatusFilterPicker: View {
    @Binding var selectedStatus: WishlistItem.Status?
    
    var body: some View {
        ForEach([nil] + WishlistItem.Status.allCases, id: \.self) { status in
            HStack {
                Text(status?.rawValue.capitalized ?? "All")
                Spacer()
                if status == selectedStatus {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStatus = status
            }
        }
    }
}

struct PriorityFilterPicker: View {
    @Binding var selectedPriority: WishlistItem.Priority?
    
    var body: some View {
        ForEach([nil] + WishlistItem.Priority.allCases, id: \.self) { priority in
            HStack {
                Text(priority?.rawValue.capitalized ?? "All")
                Spacer()
                if priority == selectedPriority {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedPriority = priority
            }
        }
    }
}

// MARK: - Preview
struct WishlistView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistView()
    }
} 