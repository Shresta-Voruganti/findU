import SwiftUI
import SDWebImageSwiftUI

struct ListingDetailView: View {
    let listing: DesignListing
    @StateObject private var viewModel = ListingDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPurchaseSheet = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Gallery
                TabView(selection: $selectedImageIndex) {
                    ForEach(listing.imageUrls.indices, id: \.self) { index in
                        WebImage(url: URL(string: listing.imageUrls[index]))
                            .resizable()
                            .placeholder {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.2))
                            }
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .scaledToFill()
                            .tag(index)
                    }
                }
                .frame(height: 400)
                .tabViewStyle(PageTabViewStyle())
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Price
                    HStack {
                        Text(listing.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(listing.formattedPrice)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Creator Info
                    NavigationLink(destination: CreatorProfileView(creatorId: listing.sellerId)) {
                        HStack {
                            WebImage(url: viewModel.creatorProfile?.avatarUrl)
                                .resizable()
                                .placeholder {
                                    Circle()
                                        .foregroundColor(.gray.opacity(0.2))
                                }
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(viewModel.creatorProfile?.brandName ?? "")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", viewModel.creatorProfile?.rating ?? 0))
                                    Text("(\(viewModel.creatorProfile?.reviewCount ?? 0) reviews)")
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            if viewModel.creatorProfile?.isVerified ?? false {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    
                    Text(listing.description)
                        .font(.body)
                    
                    // Stats
                    HStack(spacing: 20) {
                        StatBadge(count: listing.stats.views, icon: "eye")
                        StatBadge(count: listing.stats.likes, icon: "heart")
                        StatBadge(count: listing.stats.saves, icon: "bookmark")
                        StatBadge(count: listing.stats.shares, icon: "square.and.arrow.up")
                    }
                    .padding(.vertical)
                    
                    // Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(listing.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleLike(for: listing)
                } label: {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked ? .red : .primary)
                }
                
                Button {
                    viewModel.toggleSave(for: listing)
                } label: {
                    Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                }
                
                Menu {
                    Button {
                        viewModel.shareDesign(listing)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    if viewModel.isCreator {
                        Button(role: .destructive) {
                            viewModel.deleteListing(listing)
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(role: .destructive) {
                            viewModel.reportListing(listing)
                        } label: {
                            Label("Report", systemImage: "exclamationmark.triangle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                
                if listing.status == .available {
                    Button {
                        showingPurchaseSheet = true
                    } label: {
                        Text("Purchase Design")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    .padding()
                } else {
                    Text("This design has been sold")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                        .padding()
                }
            }
        )
        .sheet(isPresented: $showingPurchaseSheet) {
            PurchaseSheet(listing: listing, viewModel: viewModel)
        }
        .task {
            await viewModel.loadCreatorProfile(for: listing.sellerId)
            await viewModel.checkUserInteractions(for: listing)
        }
    }
}

struct PurchaseSheet: View {
    let listing: DesignListing
    @ObservedObject var viewModel: ListingDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Price")
                        Spacer()
                        Text(listing.formattedPrice)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Platform Fee")
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.platformFee))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total")
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.total))")
                            .fontWeight(.bold)
                    }
                }
                
                Section {
                    Text("By purchasing this design, you agree to our terms of service and the designer's usage rights.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Purchase Design")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            isProcessing = true
                            do {
                                try await viewModel.purchaseDesign(listing)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                            isProcessing = false
                        }
                    } label: {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Text("Confirm")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isProcessing)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    NavigationView {
        ListingDetailView(listing: DesignListing(
            id: "1",
            designId: "design1",
            sellerId: "seller1",
            title: "Summer Collection 2024",
            description: "A beautiful summer collection featuring light and airy pieces perfect for the season.",
            price: 49.99,
            currency: "USD",
            category: .casual,
            tags: ["summer", "casual", "trendy"],
            imageUrls: ["https://example.com/image1.jpg"],
            status: .available,
            createdAt: Date(),
            updatedAt: Date(),
            stats: DesignListing.Stats(views: 120, likes: 45, saves: 12, shares: 8)
        ))
    }
} 