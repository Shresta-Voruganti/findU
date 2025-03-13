import SwiftUI
import NukeUI

struct ItemPickerView: View {
    @ObservedObject var viewModel: ItemPickerViewModel
    
    var body: some View {
        PickerView(viewModel: viewModel) { item in
            ItemCell(item: item)
        }
    }
}

struct ItemCell: View {
    let item: Product
    
    var body: some View {
        VStack {
            LazyImage(url: URL(string: item.imageURLs.first ?? "")) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.systemGray6)
                }
            }
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
        .overlay(
            Group {
                if item.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .padding(8)
                }
            },
            alignment: .topTrailing
        )
    }
}

struct ItemPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ItemPickerView(viewModel: ItemPickerViewModel())
    }
} 