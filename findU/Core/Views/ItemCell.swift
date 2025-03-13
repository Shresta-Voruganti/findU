import SwiftUI

struct ItemCell<Item: PickerItem>: View {
    let item: Item
    let onFavorite: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Image or Preview
                ZStack(alignment: .topTrailing) {
                    if let imageURL = item.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color(.systemGray6)
                        }
                    } else {
                        Color(.systemGray6)
                    }
                    
                    // Favorite Button
                    Button(action: onFavorite) {
                        Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(item.isFavorite ? .red : .gray)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(12)
                
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    // Tags
                    if !item.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(Array(item.tags), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct ItemCell_Previews: PreviewProvider {
    struct MockItem: PickerItem {
        let id = UUID()
        let title: String
        let subtitle: String?
        let imageURL: URL?
        let tags: Set<String>
        let isFavorite: Bool
        let dateAdded = Date()
    }
    
    static var previews: some View {
        Group {
            // Basic Item
            ItemCell(
                item: MockItem(
                    title: "Basic Item",
                    subtitle: nil,
                    imageURL: nil,
                    tags: [],
                    isFavorite: false
                ),
                onFavorite: {},
                onSelect: {}
            )
            .frame(width: 200)
            .padding()
            
            // Full Item
            ItemCell(
                item: MockItem(
                    title: "Full Item",
                    subtitle: "With subtitle",
                    imageURL: URL(string: "https://example.com/image.jpg"),
                    tags: ["Tag 1", "Tag 2"],
                    isFavorite: true
                ),
                onFavorite: {},
                onSelect: {}
            )
            .frame(width: 200)
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif 