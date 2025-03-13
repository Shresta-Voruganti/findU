import SwiftUI
import SDWebImageSwiftUI

struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: DesignListing.Category?
    @State private var showingFilters = false
    @State private var sortOption: SortOption = .newest
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case priceHighToLow = "Price: High to Low"
        case priceLowToHigh = "Price: Low to High"
        case popular = "Most Popular"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(DesignListing.Category.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                title: category.rawValue,
                                isSelected: category == selectedCategory,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Listings Grid
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if viewModel.listings.isEmpty {
                        EmptyStateView()
                    } else {
                        listingsGrid
                    }
                }
                .refreshable {
                    await viewModel.fetchListings(category: selectedCategory)
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                                viewModel.sortListings(by: option)
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if option == sortOption {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search designs")
            .onChange(of: searchText) { newValue in
                Task {
                    await viewModel.searchListings(query: newValue)
                }
            }
            .onChange(of: selectedCategory) { newValue in
                Task {
                    await viewModel.fetchListings(category: newValue)
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    priceRange: $viewModel.priceRange,
                    selectedStyles: $viewModel.selectedStyles,
                    onlyVerifiedCreators: $viewModel.onlyVerifiedCreators
                )
            }
        }
    }
    
    private var listingsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.listings) { listing in
                NavigationLink(destination: ListingDetailView(listing: listing)) {
                    ListingCard(listing: listing)
                }
            }
        }
        .padding()
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ListingCard: View {
    let listing: DesignListing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            WebImage(url: URL(string: listing.imageUrls.first ?? ""))
                .resizable()
                .placeholder {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            
            // Creator Info
            HStack {
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if listing.status == .sold {
                    Text("SOLD")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
            
            Text(listing.formattedPrice)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Stats
            HStack(spacing: 12) {
                StatBadge(count: listing.stats.likes, icon: "heart")
                StatBadge(count: listing.stats.views, icon: "eye")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct StatBadge: View {
    let count: Int
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text("\(count)")
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No designs found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try adjusting your filters or search terms")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var priceRange: ClosedRange<Double>
    @Binding var selectedStyles: Set<String>
    @Binding var onlyVerifiedCreators: Bool
    
    let styles = ["Casual", "Formal", "Streetwear", "Vintage", "Minimalist", "Bohemian"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Price Range")) {
                    RangeSlider(value: $priceRange, in: 0...1000)
                        .padding(.vertical)
                    
                    HStack {
                        Text("$\(Int(priceRange.lowerBound))")
                        Spacer()
                        Text("$\(Int(priceRange.upperBound))")
                    }
                }
                
                Section(header: Text("Styles")) {
                    ForEach(styles, id: \.self) { style in
                        Toggle(style, isOn: Binding(
                            get: { selectedStyles.contains(style) },
                            set: { isSelected in
                                if isSelected {
                                    selectedStyles.insert(style)
                                } else {
                                    selectedStyles.remove(style)
                                }
                            }
                        ))
                    }
                }
                
                Section {
                    Toggle("Only Verified Creators", isOn: $onlyVerifiedCreators)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        priceRange = 0...1000
                        selectedStyles.removeAll()
                        onlyVerifiedCreators = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RangeSlider: View {
    @Binding var value: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    init(value: Binding<ClosedRange<Double>>, in bounds: ClosedRange<Double>) {
        self._value = value
        self.bounds = bounds
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: position(for: value.upperBound, in: geometry) - position(for: value.lowerBound, in: geometry))
                    .offset(x: position(for: value.lowerBound, in: geometry))
            }
            .frame(height: 2)
            .overlay(
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 2)
                        .offset(x: position(for: value.lowerBound, in: geometry) - 14)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = value(for: gesture.location.x, in: geometry)
                                    if newValue < value.upperBound {
                                        value = newValue...value.upperBound
                                    }
                                }
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 2)
                        .offset(x: position(for: value.upperBound, in: geometry) - 14)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = value(for: gesture.location.x, in: geometry)
                                    if newValue > value.lowerBound {
                                        value = value.lowerBound...newValue
                                    }
                                }
                        )
                }
            )
        }
    }
    
    private func position(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let range = bounds.upperBound - bounds.lowerBound
        let percentage = (value - bounds.lowerBound) / range
        return geometry.size.width * CGFloat(percentage)
    }
    
    private func value(for position: CGFloat, in geometry: GeometryProxy) -> Double {
        let percentage = Double(position / geometry.size.width)
        let range = bounds.upperBound - bounds.lowerBound
        return bounds.lowerBound + range * percentage
    }
}

#Preview {
    MarketplaceView()
} 