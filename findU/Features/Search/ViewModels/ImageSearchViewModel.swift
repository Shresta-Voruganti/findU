import SwiftUI
import PhotosUI

@MainActor
class ImageSearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var selectedImageSource: ImageSource?
    
    private let searchService = ImageSearchService.shared
    
    // MARK: - Image Selection
    
    func selectImage(from source: ImageSource) {
        selectedImageSource = source
        switch source {
        case .camera:
            showingCamera = true
        case .photoLibrary:
            showingImagePicker = true
        }
    }
    
    func setImage(_ image: UIImage) {
        selectedImage = image
        searchWithImage()
    }
    
    // MARK: - Search
    
    private func searchWithImage() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        
        Task {
            do {
                searchResults = try await searchService.searchOutfits(with: image)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    // MARK: - Result Management
    
    func clearResults() {
        searchResults = []
        selectedImage = nil
    }
    
    func retrySearch() {
        searchWithImage()
    }
    
    func saveSearch() {
        // Implement search history saving
    }
}

// MARK: - Supporting Types

enum ImageSource {
    case camera
    case photoLibrary
}

extension ImageSearchViewModel {
    var hasResults: Bool {
        !searchResults.isEmpty
    }
    
    var canSearch: Bool {
        selectedImage != nil && !isLoading
    }
    
    var showNoResults: Bool {
        !isLoading && hasResults && searchResults.isEmpty
    }
} 