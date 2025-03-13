import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: SearchFilters
    
    @State private var selectedCategory: SearchCategory?
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 1000
    @State private var selectedBrands: Set<String> = []
    @State private var sortOption: SearchSortOption = .relevance
    @State private var showInStockOnly = false
    
    private let brands = ["Nike", "Adidas", "Zara", "H&M", "Gucci", "Prada", "Uniqlo"] // Replace with actual brands
    
    var body: some View {
        NavigationView {
            Form {
                // Category Section
                Section(header: Text("Category")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SearchCategory.allCases) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                // Price Range Section
                Section(header: Text("Price Range")) {
                    VStack {
                        HStack {
                            Text("$\(Int(minPrice))")
                            Spacer()
                            Text("$\(Int(maxPrice))")
                        }
                        .font(.caption)
                        
                        RangeSlider(
                            minValue: $minPrice,
                            maxValue: $maxPrice,
                            range: 0...1000
                        )
                    }
                }
                
                // Brands Section
                Section(header: Text("Brands")) {
                    ForEach(brands, id: \.self) { brand in
                        Toggle(brand, isOn: Binding(
                            get: { selectedBrands.contains(brand) },
                            set: { isSelected in
                                if isSelected {
                                    selectedBrands.insert(brand)
                                } else {
                                    selectedBrands.remove(brand)
                                }
                            }
                        ))
                    }
                }
                
                // Sort By Section
                Section(header: Text("Sort By")) {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SearchSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Additional Options Section
                Section {
                    Toggle("Show In-Stock Items Only", isOn: $showInStockOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                }
            }
        }
    }
    
    private func resetFilters() {
        selectedCategory = nil
        minPrice = 0
        maxPrice = 1000
        selectedBrands.removeAll()
        sortOption = .relevance
        showInStockOnly = false
    }
    
    private func applyFilters() {
        filters.category = selectedCategory
        filters.priceRange = minPrice...maxPrice
        filters.brands = selectedBrands
        filters.sortBy = sortOption
        filters.onlyInStock = showInStockOnly
        dismiss()
    }
}

struct CategoryButton: View {
    let category: SearchCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: width(for: maxValue, in: geometry) - width(for: minValue, in: geometry),
                           height: 4)
                    .offset(x: width(for: minValue, in: geometry))
                
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(x: width(for: minValue, in: geometry))
                        .gesture(dragGesture(for: $minValue, in: geometry))
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(x: width(for: maxValue, in: geometry))
                        .gesture(dragGesture(for: $maxValue, in: geometry))
                }
            }
        }
        .frame(height: 24)
    }
    
    private func width(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let range = range.upperBound - range.lowerBound
        let percentage = (value - range.lowerBound) / range
        return (geometry.size.width - 24) * CGFloat(percentage)
    }
    
    private func dragGesture(for value: Binding<Double>, in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                let range = range.upperBound - range.lowerBound
                let percentage = Double(gesture.location.x / (geometry.size.width - 24))
                let newValue = range.lowerBound + (range * percentage)
                value.wrappedValue = min(max(newValue, range.lowerBound), range.upperBound)
            }
    }
}

// Preview
struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView(filters: .constant(SearchFilters()))
    }
} 