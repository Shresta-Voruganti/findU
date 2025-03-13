import SwiftUI

struct TrendingFeedView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.trendingFeed.isEmpty {
                FeedLoadingView()
            } else if viewModel.trendingFeed.isEmpty {
                EmptyFeedView(
                    title: "No Trending Content",
                    message: "Check back later to see what's trending in the findU community.",
                    action: nil,
                    actionTitle: nil
                )
            } else {
                FeedList(
                    items: viewModel.trendingFeed,
                    onAction: { action, item in
                        Task {
                            await viewModel.performAction(action, on: item)
                        }
                    },
                    onRefresh: {
                        await viewModel.refreshFeed()
                    },
                    onLoadMore: {
                        // Implement pagination
                    }
                )
            }
        }
    }
} 