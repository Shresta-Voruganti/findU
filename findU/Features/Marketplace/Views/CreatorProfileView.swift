import SwiftUI
import SDWebImageSwiftUI

struct CreatorProfileView: View {
    let creatorId: String
    @StateObject private var viewModel = CreatorProfileViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    WebImage(url: viewModel.profile?.avatarUrl)
                        .resizable()
                        .placeholder {
                            Circle()
                                .foregroundColor(.gray.opacity(0.2))
                        }
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(viewModel.profile?.brandName ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if viewModel.profile?.isVerified ?? false {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(viewModel.profile?.bio ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal)
                
                // Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("\(viewModel.profile?.designCount ?? 0)")
                            .font(.headline)
                        Text("Designs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(viewModel.profile?.salesCount ?? 0)")
                            .font(.headline)
                        Text("Sales")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text(String(format: "%.1f", viewModel.profile?.rating ?? 0))
                            .font(.headline)
                        Text("Rating")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical)
                
                // Action Buttons
                if !viewModel.isCurrentUser {
                    HStack(spacing: 16) {
                        Button {
                            viewModel.toggleFollow()
                        } label: {
                            Text(viewModel.isFollowing ? "Following" : "Follow")
                                .font(.headline)
                                .foregroundColor(viewModel.isFollowing ? .primary : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(viewModel.isFollowing ? Color(.systemGray6) : Color.accentColor)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            viewModel.startChat()
                        } label: {
                            Text("Message")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Content Tabs
                Picker("Content", selection: $selectedTab) {
                    Text("Designs").tag(0)
                    Text("Reviews").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content
                if selectedTab == 0 {
                    designsGrid
                } else {
                    reviewsList
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile(creatorId: creatorId)
        }
    }
    
    private var designsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.designs) { design in
                NavigationLink(destination: ListingDetailView(listing: design)) {
                    ListingCard(listing: design)
                }
            }
        }
        .padding()
    }
    
    private var reviewsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.reviews) { review in
                ReviewCard(review: review)
            }
        }
        .padding()
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                WebImage(url: review.reviewerAvatarUrl)
                    .resizable()
                    .placeholder {
                        Circle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(review.reviewerName)
                        .font(.headline)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        
                        Text(review.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(review.comment)
                .font(.body)
            
            if let designTitle = review.designTitle {
                Text("Design: \(designTitle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button {
                    // Handle helpful button tap
                } label: {
                    HStack {
                        Image(systemName: "hand.thumbsup")
                        Text("Helpful (\(review.helpfulCount))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if review.verifiedPurchase {
                    Label("Verified Purchase", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        CreatorProfileView(creatorId: "creator1")
    }
} 