import SwiftUI

struct FeedItemView: View {
    let item: FeedItem
    let onAction: (FeedAction) -> Void
    
    @State private var isLiked = false
    @State private var showingComments = false
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            HStack {
                NavigationLink(destination: ProfileView(userId: item.userId)) {
                    HStack {
                        AsyncImage(url: URL(string: item.userAvatarUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(item.username)
                                .font(.headline)
                            Text(item.location ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Menu {
                    if item.isMine {
                        Button(role: .destructive) {
                            onAction(.delete)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            onAction(.edit)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    } else {
                        Button {
                            onAction(.report)
                        } label: {
                            Label("Report", systemImage: "exclamationmark.triangle")
                        }
                        
                        Button {
                            onAction(.share)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
            
            // Content
            switch item.type {
            case .design:
                DesignFeedItem(design: item.content as! DesignContent)
                    .onTapGesture {
                        showingDetail = true
                    }
            case .activity:
                ActivityFeedItem(activity: item.content as! ActivityContent)
                    .onTapGesture {
                        showingDetail = true
                    }
            case .recommendation:
                RecommendationFeedItem(recommendation: item.content as! RecommendationContent)
                    .onTapGesture {
                        showingDetail = true
                    }
            case .featured:
                FeaturedFeedItem(featured: item.content as! FeaturedContent)
                    .onTapGesture {
                        showingDetail = true
                    }
            }
            
            // Interaction Bar
            HStack(spacing: 20) {
                Button {
                    isLiked.toggle()
                    onAction(.like)
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .primary)
                }
                
                Button {
                    showingComments = true
                } label: {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.primary)
                }
                
                Button {
                    onAction(.save)
                } label: {
                    Image(systemName: "bookmark")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                ContentStats(stats: item.stats)
            }
            
            // Caption
            if let caption = item.caption {
                Text(caption)
                    .font(.body)
            }
            
            // Timestamp
            Text(item.timestamp.timeAgoDisplay())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .sheet(isPresented: $showingComments) {
            CommentsView(itemId: item.id)
        }
        .sheet(isPresented: $showingDetail) {
            FeedItemDetailView(item: item)
        }
    }
}

// MARK: - Feed Item Types

struct DesignFeedItem: View {
    let design: DesignContent
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: design.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .cornerRadius(10)
            
            if !design.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(design.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

struct ActivityFeedItem: View {
    let activity: ActivityContent
    
    var body: some View {
        VStack(spacing: 8) {
            Text(activity.title)
                .font(.headline)
            
            Text(activity.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let imageUrl = activity.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .cornerRadius(10)
            }
        }
    }
}

struct RecommendationFeedItem: View {
    let recommendation: RecommendationContent
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Recommended for You")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendation.items) { item in
                        VStack(alignment: .leading) {
                            AsyncImage(url: URL(string: item.imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.2))
                            }
                            .frame(width: 120, height: 160)
                            .cornerRadius(8)
                            
                            Text(item.title)
                                .font(.caption)
                                .lineLimit(2)
                            
                            Text(item.price)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 120)
                    }
                }
            }
        }
    }
}

struct FeaturedFeedItem: View {
    let featured: FeaturedContent
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: featured.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .cornerRadius(10)
            
            Text(featured.title)
                .font(.headline)
            
            Text(featured.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let callToAction = featured.callToAction {
                Button(callToAction.title) {
                    // Handle call to action
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Supporting Views

struct ContentStats: View {
    let stats: FeedItemStats
    
    var body: some View {
        HStack(spacing: 15) {
            Label("\(stats.likes)", systemImage: "heart")
            Label("\(stats.comments)", systemImage: "bubble.right")
            Label("\(stats.shares)", systemImage: "square.and.arrow.up")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

// MARK: - Preview

#Preview {
    FeedItemView(
        item: FeedItem(
            id: "1",
            type: .design,
            userId: "user1",
            username: "fashionista",
            userAvatarUrl: "",
            content: DesignContent(
                imageUrl: "",
                tags: ["summer", "casual"]
            ),
            caption: "Summer vibes ☀️",
            location: "New York",
            timestamp: Date(),
            stats: FeedItemStats(likes: 123, comments: 45, shares: 12)
        )
    ) { action in
        print("Action: \(action)")
    }
} 