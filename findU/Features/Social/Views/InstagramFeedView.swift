import SwiftUI
import SDWebImageSwiftUI

struct InstagramFeedView: View {
    @StateObject private var viewModel = InstagramFeedViewModel()
    @State private var showingAuthSheet = false
    @State private var showingShareSheet = false
    @State private var selectedDesign: DesignListing?
    
    var body: some View {
        NavigationView {
            Group {
                if !viewModel.isConnected {
                    connectView
                } else if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.feed.isEmpty {
                    emptyView
                } else {
                    feedView
                }
            }
            .navigationTitle("Instagram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.isConnected {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.disconnect()
                                }
                            } label: {
                                Label("Disconnect", systemImage: "link.badge.minus")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.checkConnectionStatus()
            if viewModel.isConnected {
                await viewModel.fetchFeed()
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            InstagramAuthSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareDesignSheet(viewModel: viewModel)
        }
    }
    
    private var connectView: some View {
        VStack(spacing: 20) {
            Image("instagram_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            
            Text("Connect with Instagram")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Share your designs and get inspired by others")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingAuthSheet = true
            } label: {
                Text("Connect Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Posts Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Share your first design on Instagram")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingShareSheet = true
            } label: {
                Text("Share Design")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }
    
    private var feedView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.feed, id: \.id) { post in
                    InstagramPostCard(post: post)
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.fetchFeed()
        }
    }
}

struct InstagramAuthSheet: View {
    @ObservedObject var viewModel: InstagramFeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                ProgressView()
                    .padding()
            }
            .navigationTitle("Connect Instagram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                do {
                    try await viewModel.connect()
                    dismiss()
                } catch {
                    // Handle error
                }
            }
        }
    }
}

struct ShareDesignSheet: View {
    @ObservedObject var viewModel: InstagramFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDesign: DesignListing?
    @State private var caption = ""
    @State private var isSharing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Design")) {
                    if let design = selectedDesign {
                        HStack {
                            WebImage(url: URL(string: design.imageUrls.first ?? ""))
                                .resizable()
                                .placeholder {
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.2))
                                }
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text(design.title)
                                    .font(.headline)
                                Text(design.formattedPrice)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                selectedDesign = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        NavigationLink("Select Design") {
                            DesignSelectionView(selectedDesign: $selectedDesign)
                        }
                    }
                }
                
                Section(header: Text("Caption")) {
                    TextEditor(text: $caption)
                        .frame(height: 100)
                }
                
                Section {
                    Button {
                        Task {
                            await shareDesign()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSharing {
                                ProgressView()
                            } else {
                                Text("Share to Instagram")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(selectedDesign == nil || isSharing)
                }
            }
            .navigationTitle("Share to Instagram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func shareDesign() async {
        guard let design = selectedDesign else { return }
        
        isSharing = true
        defer { isSharing = false }
        
        do {
            try await viewModel.shareDesign(design, caption: caption)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct DesignSelectionView: View {
    @Binding var selectedDesign: DesignListing?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DesignSelectionViewModel()
    
    var body: some View {
        List(viewModel.designs) { design in
            Button {
                selectedDesign = design
                dismiss()
            } label: {
                HStack {
                    WebImage(url: URL(string: design.imageUrls.first ?? ""))
                        .resizable()
                        .placeholder {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.2))
                        }
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading) {
                        Text(design.title)
                            .font(.headline)
                        Text(design.formattedPrice)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .navigationTitle("Select Design")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDesigns()
        }
    }
}

struct InstagramPostCard: View {
    let post: InstagramMedia
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WebImage(url: URL(string: post.mediaUrl))
                .resizable()
                .placeholder {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
            
            if let caption = post.caption {
                Text(caption)
                    .font(.body)
            }
            
            HStack {
                Text(post.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Link(destination: URL(string: post.permalink)!) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

private extension InstagramMedia {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let date = formatter.date(from: timestamp) else { return "" }
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    InstagramFeedView()
} 