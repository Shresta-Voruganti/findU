import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var forYouFeed: [FeedItem] = []
    @Published private(set) var followingFeed: [FeedItem] = []
    @Published private(set) var trendingFeed: [FeedItem] = []
    @Published private(set) var notifications: [FeedNotification] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var isLoadingMore = false
    @Published var selectedTab: Int = 0
    @Published var filter = FeedFilter()
    @Published var showingError = false
    @Published var showingUserSuggestions = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let feedService: FeedServiceProtocol
    private let userService: UserServiceProtocol
    private let notificationService: NotificationServiceProtocol
    
    private var lastForYouDocument: QueryDocumentSnapshot?
    private var lastFollowingDocument: QueryDocumentSnapshot?
    private var lastTrendingDocument: QueryDocumentSnapshot?
    
    private var canLoadMoreForYou = true
    private var canLoadMoreFollowing = true
    private var canLoadMoreTrending = true
    
    // MARK: - Initialization
    
    init(
        feedService: FeedServiceProtocol,
        userService: UserServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.feedService = feedService
        self.userService = userService
        self.notificationService = notificationService
        
        setupSubscriptions()
        setupErrorHandling()
    }
    
    // MARK: - Public Methods
    
    func refreshFeed() async {
        isLoading = true
        error = nil
        
        // Reset pagination state
        lastForYouDocument = nil
        lastFollowingDocument = nil
        lastTrendingDocument = nil
        canLoadMoreForYou = true
        canLoadMoreFollowing = true
        canLoadMoreTrending = true
        
        do {
            switch selectedTab {
            case 0:
                let (items, lastDoc) = try await feedService.fetchForYouFeed(
                    filter: filter,
                    startAfter: nil
                )
                forYouFeed = items
                lastForYouDocument = lastDoc
                canLoadMoreForYou = lastDoc != nil
            case 1:
                let (items, lastDoc) = try await feedService.fetchFollowingFeed(
                    filter: filter,
                    startAfter: nil
                )
                followingFeed = items
                lastFollowingDocument = lastDoc
                canLoadMoreFollowing = lastDoc != nil
            case 2:
                let (items, lastDoc) = try await feedService.fetchTrendingFeed(
                    filter: filter,
                    startAfter: nil
                )
                trendingFeed = items
                lastTrendingDocument = lastDoc
                canLoadMoreTrending = lastDoc != nil
            default:
                break
            }
        } catch {
            self.error = error
            showingError = true
        }
        
        isLoading = false
    }
    
    func loadMoreForYou() async {
        guard !isLoadingMore && canLoadMoreForYou else { return }
        await loadMore(for: .forYou)
    }
    
    func loadMoreFollowing() async {
        guard !isLoadingMore && canLoadMoreFollowing else { return }
        await loadMore(for: .following)
    }
    
    func loadMoreTrending() async {
        guard !isLoadingMore && canLoadMoreTrending else { return }
        await loadMore(for: .trending)
    }
    
    func performAction(_ action: FeedAction, on item: FeedItem) async {
        do {
            switch action {
            case .like:
                try await feedService.likeFeedItem(item.id)
            case .comment:
                // Handle in CommentSheet
                break
            case .share:
                try await feedService.shareFeedItem(item.id)
            case .save:
                try await feedService.saveFeedItem(item.id)
            case .delete:
                guard item.isMine else { return }
                try await feedService.deleteFeedItem(item.id)
                await refreshFeed()
            case .edit:
                guard item.isMine else { return }
                // Handle in EditSheet
                break
            case .report:
                try await feedService.reportFeedItem(item.id)
            }
        } catch {
            self.error = error
            showingError = true
        }
    }
    
    func fetchNotifications() async {
        do {
            notifications = try await notificationService.fetchNotifications()
        } catch {
            self.error = error
            showingError = true
        }
    }
    
    func markNotificationAsRead(_ notification: FeedNotification) async {
        do {
            try await notificationService.markAsRead(notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
        } catch {
            self.error = error
            showingError = true
        }
    }
    
    func showUserSuggestions() {
        showingUserSuggestions = true
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to real-time updates
        feedService.feedUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleFeedUpdate(update)
            }
            .store(in: &cancellables)
        
        notificationService.notificationUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.notifications.insert(notification, at: 0)
            }
            .store(in: &cancellables)
    }
    
    private func setupErrorHandling() {
        $error
            .map { $0 != nil }
            .assign(to: &$showingError)
    }
    
    private func loadMore(for feedType: FeedType) async {
        isLoadingMore = true
        
        do {
            switch feedType {
            case .forYou:
                let (items, lastDoc) = try await feedService.fetchForYouFeed(
                    filter: filter,
                    startAfter: lastForYouDocument
                )
                forYouFeed.append(contentsOf: items)
                lastForYouDocument = lastDoc
                canLoadMoreForYou = lastDoc != nil
                
            case .following:
                let (items, lastDoc) = try await feedService.fetchFollowingFeed(
                    filter: filter,
                    startAfter: lastFollowingDocument
                )
                followingFeed.append(contentsOf: items)
                lastFollowingDocument = lastDoc
                canLoadMoreFollowing = lastDoc != nil
                
            case .trending:
                let (items, lastDoc) = try await feedService.fetchTrendingFeed(
                    filter: filter,
                    startAfter: lastTrendingDocument
                )
                trendingFeed.append(contentsOf: items)
                lastTrendingDocument = lastDoc
                canLoadMoreTrending = lastDoc != nil
            }
        } catch {
            self.error = error
            showingError = true
        }
        
        isLoadingMore = false
    }
    
    private func handleFeedUpdate(_ update: FeedUpdate) {
        // Update the appropriate feed based on the update type
        switch update.type {
        case .new:
            insertNewItem(update.item)
        case .modified:
            updateExistingItem(update.item)
        case .deleted:
            removeItem(update.item.id)
        }
    }
    
    private func insertNewItem(_ item: FeedItem) {
        switch selectedTab {
        case 0:
            forYouFeed.insert(item, at: 0)
        case 1:
            followingFeed.insert(item, at: 0)
        case 2:
            trendingFeed.insert(item, at: 0)
        default:
            break
        }
    }
    
    private func updateExistingItem(_ item: FeedItem) {
        let feeds = [&forYouFeed, &followingFeed, &trendingFeed]
        for feed in feeds {
            if let index = feed.firstIndex(where: { $0.id == item.id }) {
                feed[index] = item
            }
        }
    }
    
    private func removeItem(_ itemId: String) {
        let feeds = [&forYouFeed, &followingFeed, &trendingFeed]
        for feed in feeds {
            feed.removeAll { $0.id == itemId }
        }
    }
}

// MARK: - Supporting Types

enum FeedType {
    case forYou
    case following
    case trending
}

struct FeedUpdate {
    let type: UpdateType
    let item: FeedItem
}

enum UpdateType {
    case new
    case modified
    case deleted
}

// MARK: - Service Protocols

protocol FeedServiceProtocol {
    var feedUpdates: AnyPublisher<FeedUpdate, Never> { get }
    
    func fetchForYouFeed(filter: FeedFilter, startAfter: QueryDocumentSnapshot?) async throws -> ([FeedItem], QueryDocumentSnapshot?)
    func fetchFollowingFeed(filter: FeedFilter, startAfter: QueryDocumentSnapshot?) async throws -> ([FeedItem], QueryDocumentSnapshot?)
    func fetchTrendingFeed(filter: FeedFilter, startAfter: QueryDocumentSnapshot?) async throws -> ([FeedItem], QueryDocumentSnapshot?)
    func likeFeedItem(_ id: String) async throws
    func shareFeedItem(_ id: String) async throws
    func saveFeedItem(_ id: String) async throws
    func deleteFeedItem(_ id: String) async throws
    func reportFeedItem(_ id: String) async throws
}

protocol NotificationServiceProtocol {
    var notificationUpdates: AnyPublisher<FeedNotification, Never> { get }
    
    func fetchNotifications() async throws -> [FeedNotification]
    func markAsRead(_ id: String) async throws
}

// Add more home-related view model functionality as needed 