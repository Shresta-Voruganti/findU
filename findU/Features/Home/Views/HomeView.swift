import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showingNotifications = false
    @State private var showingUserSuggestions = false
    
    init(feedService: FeedServiceProtocol, userService: UserServiceProtocol, notificationService: NotificationServiceProtocol) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            feedService: feedService,
            userService: userService,
            notificationService: notificationService
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom segmented control
                CustomSegmentedControl(
                    selection: $viewModel.selectedTab,
                    options: ["For You", "Following", "Trending"]
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Feed content
                TabView(selection: $viewModel.selectedTab) {
                    ForYouFeedView(viewModel: viewModel)
                        .tag(0)
                    
                    FollowingFeedView(viewModel: viewModel)
                        .tag(1)
                    
                    TrendingFeedView(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .navigationTitle("findU")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await viewModel.refreshFeed()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNotifications = true
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingUserSuggestions) {
                UserSuggestionsView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
        .task {
            await viewModel.refreshFeed()
        }
    }
}

// MARK: - Feed Views

struct ForYouFeedView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        FeedList(items: viewModel.forYouFeed) { item in
            FeedItemView(item: item) { action in
                viewModel.handleInteraction(action, on: item)
            }
        }
    }
}

struct FollowingFeedView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        if viewModel.followingFeed.isEmpty {
            EmptyFollowingView(viewModel: viewModel)
        } else {
            FeedList(items: viewModel.followingFeed) { item in
                FeedItemView(item: item) { action in
                    viewModel.handleInteraction(action, on: item)
                }
            }
        }
    }
}

struct TrendingFeedView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        FeedList(items: viewModel.trendingFeed) { item in
            FeedItemView(item: item) { action in
                viewModel.handleInteraction(action, on: item)
            }
        }
    }
}

// MARK: - Supporting Views

struct FeedList<Content: View>: View {
    let items: [FeedItem]
    let content: (FeedItem) -> Content
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    content(item)
                }
            }
            .padding()
        }
    }
}

struct EmptyFollowingView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Find People to Follow")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Follow other fashion enthusiasts to see their outfits and designs in your feed")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: { viewModel.showUserSuggestions() }) {
                Text("Discover People")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct CustomSegmentedControl: View {
    @Binding var selection: Int
    let options: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                Button {
                    withAnimation {
                        selection = index
                    }
                } label: {
                    Text(options[index])
                        .fontWeight(selection == index ? .semibold : .regular)
                        .foregroundColor(selection == index ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
        }
        .background {
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width / CGFloat(options.count))
                    .offset(x: CGFloat(selection) * geometry.size.width / CGFloat(options.count))
                    .frame(height: 2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification)
                        .onTapGesture {
                            Task {
                                await viewModel.markNotificationAsRead(notification)
                            }
                        }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchNotifications()
        }
    }
}

struct NotificationRow: View {
    let notification: FeedNotification
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: notification.userAvatarUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(notification.isRead ? .secondary : .primary)
                
                Text(notification.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !notification.isRead {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct UserSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                // Implement user suggestions view
                Text("User suggestions coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Suggested Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(
        feedService: PreviewFeedService(),
        userService: PreviewUserService(),
        notificationService: PreviewNotificationService()
    )
}

// MARK: - Preview Services

class PreviewFeedService: FeedServiceProtocol {
    var feedUpdates: AnyPublisher<FeedUpdate, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    func fetchForYouFeed(filter: FeedFilter) async throws -> [FeedItem] { [] }
    func fetchFollowingFeed(filter: FeedFilter) async throws -> [FeedItem] { [] }
    func fetchTrendingFeed(filter: FeedFilter) async throws -> [FeedItem] { [] }
    func likeFeedItem(_ id: String) async throws {}
    func shareFeedItem(_ id: String) async throws {}
    func saveFeedItem(_ id: String) async throws {}
    func deleteFeedItem(_ id: String) async throws {}
    func reportFeedItem(_ id: String) async throws {}
}

class PreviewUserService: UserServiceProtocol {}

class PreviewNotificationService: NotificationServiceProtocol {
    var notificationUpdates: AnyPublisher<FeedNotification, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    func fetchNotifications() async throws -> [FeedNotification] { [] }
    func markAsRead(_ id: String) async throws {}
} 
} 