import SwiftUI

struct ForYouFeedView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.forYouFeed.isEmpty {
                FeedLoadingView()
            } else if viewModel.forYouFeed.isEmpty {
                EmptyFeedView(
                    title: "Welcome to findU",
                    message: "Follow your favorite creators and explore trending designs to personalize your feed.",
                    action: {
                        // Navigate to discovery/explore
                    },
                    actionTitle: "Explore Trending"
                )
            } else {
                FeedList(
                    items: viewModel.forYouFeed,
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