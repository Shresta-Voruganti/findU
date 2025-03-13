import SwiftUI

struct FeedList: View {
    let items: [FeedItem]
    let onAction: (FeedAction, FeedItem) -> Void
    let onRefresh: () async -> Void
    let onLoadMore: () async -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    FeedItemView(item: item) { action in
                        onAction(action, item)
                    }
                    .onAppear {
                        if item.id == items.last?.id {
                            Task {
                                await onLoadMore()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .refreshable {
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
    }
}

struct EmptyFeedView: View {
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

struct FeedLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { _ in
                FeedItemLoadingView()
            }
        }
        .padding()
    }
}

struct FeedItemLoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 16)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 12)
                }
            }
            
            // Content placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Action bar
            HStack(spacing: 24) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

struct ShimmeringView: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.5),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    .blendMode(.screen)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmeringView())
    }
}

#Preview {
    FeedList(
        items: [],
        onAction: { _, _ in },
        onRefresh: { },
        onLoadMore: { }
    )
} 