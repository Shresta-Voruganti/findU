import SwiftUI
import NukeUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory?
    @State private var showImageSearch = false
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeader
                
                // Category Selector
                categorySelector
                
                // Results or Empty State
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty {
                    emptyStateView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showImageSearch) {
                ImageSearchView()
            }
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $viewModel.filters)
            }
        }
    }
    
    private var searchHeader: some View {
        HStack(spacing: 12) {
            // Search TextField
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search products, styles...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        viewModel.search(query: newValue)
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Image Search Button
            Button {
                showImageSearch.toggle()
            } label: {
                Image(systemName: "camera")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SearchCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                        viewModel.filterByCategory(category)
                    } label: {
                        Text(category.name)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.accentColor : Color(.systemGray6))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.searchResults) { result in
                    SearchResultCard(result: result)
                        .onAppear {
                            if result == viewModel.searchResults.last {
                                viewModel.loadMoreResults()
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No results found")
                .font(.headline)
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(product: result.product)) {
            VStack(alignment: .leading, spacing: 8) {
                LazyImage(url: URL(string: result.product.imageURLs.first ?? "")) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray6))
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(result.product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(result.product.brand)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(String(format: "$%.2f", result.product.price))
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
} 