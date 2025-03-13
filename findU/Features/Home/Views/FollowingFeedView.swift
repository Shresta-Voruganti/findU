import SwiftUI

struct FollowingFeedView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.followingFeed.isEmpty {
                FeedLoadingView()
            } else if viewModel.followingFeed.isEmpty {
                EmptyFeedView(
                    title: "Find People to Follow",
                    message: "Follow other fashion enthusiasts to see their outfits and designs in your feed.",
                    action: {
                        viewModel.showUserSuggestions()
                    },
                    actionTitle: "Discover People"
                )
            } else {
                FeedList(
                    items: viewModel.followingFeed,
                    onAction: { action, item in
                        Task {
                            await viewModel.performAction(action, on: item)
                        }
                    },
                    onRefresh: {
                        await viewModel.refreshFeed()
                    },
                    onLoadMore: {
                        await viewModel.loadMoreFollowing()
                    }
                )
            }
        }
    }
} 