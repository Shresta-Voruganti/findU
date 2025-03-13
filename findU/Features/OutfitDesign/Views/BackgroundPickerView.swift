import SwiftUI
import NukeUI

struct BackgroundPickerView: View {
    @ObservedObject var viewModel: BackgroundPickerViewModel
    
    var body: some View {
        PickerView(viewModel: viewModel) { item in
            BackgroundCell(item: item)
        }
    }
}

struct BackgroundCell: View {
    let item: BackgroundTemplate
    
    var body: some View {
        Group {
            switch item.type {
            case .solid(let color):
                color
            case .gradient(let colors, let angle):
                LinearGradient(colors: colors,
                             startPoint: .top,
                             endPoint: .bottom)
                    .rotationEffect(.degrees(angle))
            case .image(let url):
                LazyImage(url: URL(string: url)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(.systemGray6)
                    }
                }
            case .pattern(let type, let colors):
                PatternView(type: type, colors: colors)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
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

struct BackgroundPickerView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundPickerView(viewModel: BackgroundPickerViewModel())
    }
} 