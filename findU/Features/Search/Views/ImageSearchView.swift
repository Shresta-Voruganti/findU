import SwiftUI
import PhotosUI

struct ImageSearchView: View {
    @StateObject private var viewModel = ImageSearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.selectedImage == nil {
                    // Image Selection View
                    ImageSelectionView(viewModel: viewModel)
                } else if viewModel.isLoading {
                    // Loading View
                    LoadingView()
                } else if viewModel.showNoResults {
                    // No Results View
                    NoResultsView(viewModel: viewModel)
                } else {
                    // Results View
                    SearchResultsView(viewModel: viewModel)
                }
            }
            .navigationTitle("Find Similar Outfits")
            .toolbar {
                if viewModel.selectedImage != nil {
                    Button("Clear") {
                        viewModel.clearResults()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage)
            }
            .fullScreenCover(isPresented: $viewModel.showingCamera) {
                CameraView(image: $viewModel.selectedImage)
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { _ in viewModel.error = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Image Selection View

struct ImageSelectionView: View {
    @ObservedObject var viewModel: ImageSearchViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Search by Image")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Take a photo or select from your library to find similar outfits")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                Button(action: {
                    viewModel.selectImage(from: .camera)
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    viewModel.selectImage(from: .photoLibrary)
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Library")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching for similar outfits...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - No Results View

struct NoResultsView: View {
    @ObservedObject var viewModel: ImageSearchViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No matches found")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Try another image or adjust your search")
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                viewModel.retrySearch()
            }
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// MARK: - Results View

struct SearchResultsView: View {
    @ObservedObject var viewModel: ImageSearchViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if let selectedImage = viewModel.selectedImage {
                // Query Image
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .padding(.bottom)
            }
            
            // Results Grid
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(viewModel.searchResults) { result in
                    NavigationLink(destination: OutfitDetailView(outfit: result)) {
                        SearchResultCell(result: result)
                    }
                }
            }
            .padding()
        }
    }
}

struct SearchResultCell: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            AsyncImage(url: URL(string: result.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.systemGray6)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(result.title)
                    .font(.subheadline)
                    .lineLimit(2)
                
                Text("$\(result.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ImageSearchView()
} 