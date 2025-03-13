import SwiftUI
import NukeUI

struct DesignCanvasView: View {
    @ObservedObject var viewModel: OutfitDesignViewModel
    
    var body: some View {
        CanvasView(viewModel: viewModel) { item, isSelected in
            DesignItemView(item: item, isSelected: isSelected)
        }
    }
}

struct DesignItemView: View {
    let item: DesignItem
    let isSelected: Bool
    
    var body: some View {
        Group {
            switch item.type {
            case .garment(let garment):
                LazyImage(url: URL(string: garment.imageURL)) { state in
                    if let image = state.image {
                        image.resizable()
                    } else {
                        Color(.systemGray6)
                    }
                }
            case .pattern(let pattern):
                PatternView(type: pattern.type, colors: pattern.colors)
            case .text(let text):
                Text(text.content)
                    .font(.system(size: text.fontSize))
                    .foregroundColor(text.color)
            }
        }
    }
}

struct DesignCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        DesignCanvasView(viewModel: OutfitDesignViewModel())
    }
} 