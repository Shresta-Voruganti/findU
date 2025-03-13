import SwiftUI
import PhotosUI

struct WishlistItemDetailView: View {
    @ObservedObject var viewModel: WishlistViewModel
    let item: WishlistItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingImagePicker = false
    @State private var showingPriceHistory = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var targetPrice: Double?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                // Image Section
                Section {
                    if let imageUrl = item.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Label(item.imageUrl == nil ? "Add Image" : "Change Image", 
                              systemImage: "photo")
                    }
                }
                
                // Details Section
                Section("Details") {
                    HStack {
                        Text("Current Price")
                        Spacer()
                        Text(String(format: "$%.2f", item.price ?? 0))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Target Price")
                        Spacer()
                        TextField("Set Target", value: $targetPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Button("View Price History") {
                        showingPriceHistory = true
                    }
                }
                
                // Status Section
                Section("Status") {
                    Picker("Status", selection: Binding(
                        get: { item.status },
                        set: { newStatus in
                            Task {
                                try await viewModel.updateItemStatus(item, status: newStatus)
                            }
                        }
                    )) {
                        ForEach(WishlistItem.Status.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized)
                                .tag(status)
                        }
                    }
                    
                    Picker("Priority", selection: Binding(
                        get: { item.priority },
                        set: { newPriority in
                            Task {
                                try await viewModel.updateItemPriority(item, priority: newPriority)
                            }
                        }
                    )) {
                        ForEach(WishlistItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized)
                                .tag(priority)
                        }
                    }
                }
                
                // Price Alerts Section
                Section("Price Alerts") {
                    Toggle("Enable Price Drop Alerts", isOn: Binding(
                        get: { item.notificationEnabled },
                        set: { enabled in
                            Task {
                                try await viewModel.updateNotificationSettings(item, enabled: enabled)
                            }
                        }
                    ))
                    
                    if item.notificationEnabled {
                        HStack {
                            Text("Alert Threshold")
                            Spacer()
                            TextField("% below current", value: Binding(
                                get: { item.priceAlert?.threshold ?? 10 },
                                set: { threshold in
                                    Task {
                                        try await viewModel.updatePriceAlertThreshold(item, threshold: threshold)
                                    }
                                }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            Text("%")
                        }
                    }
                }
                
                // Notes Section
                Section("Notes") {
                    TextField("Add a note", text: Binding(
                        get: { item.note ?? "" },
                        set: { newNote in
                            Task {
                                try await viewModel.updateItemNote(item, note: newNote)
                            }
                        }
                    ), axis: .vertical)
                }
                
                // Sharing Section
                Section {
                    Button(action: { showingShareSheet = true }) {
                        Label("Share Item", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImage) { newItem in
                if let newItem {
                    Task {
                        try await viewModel.uploadItemImage(item, image: newItem)
                    }
                }
            }
            .sheet(isPresented: $showingPriceHistory) {
                PriceHistoryView(item: item)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(item: item)
            }
        }
    }
}

// Price History View
struct PriceHistoryView: View {
    let item: WishlistItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(item.priceHistory ?? [], id: \.date) { record in
                    HStack {
                        Text(record.date.formatted(date: .abbreviated, time: .shortened))
                        Spacer()
                        Text(String(format: "$%.2f", record.price))
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Price History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Share Sheet
struct ShareSheet: View {
    let item: WishlistItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ShareLink(
                        item: "Check out this item on my wishlist!",
                        preview: SharePreview(
                            item.note ?? "Wishlist Item",
                            image: item.imageUrl.flatMap { URL(string: $0) }.map { Image(url: $0) } ?? Image(systemName: "gift")
                        )
                    )
                }
                
                Section("Share With") {
                    Button {
                        // TODO: Implement direct sharing
                        dismiss()
                    } label: {
                        Label("Share with Friends", systemImage: "person.2")
                    }
                    
                    Button {
                        // TODO: Implement collection sharing
                        dismiss()
                    } label: {
                        Label("Add to Shared Collection", systemImage: "folder.badge.person.crop")
                    }
                }
            }
            .navigationTitle("Share Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 