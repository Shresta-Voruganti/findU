import SwiftUI
import PhotosUI

struct CreateListingView: View {
    let listing: DesignListing?
    @StateObject private var viewModel = CreateListingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingTagSheet = false
    @State private var showingDiscardAlert = false
    @State private var newTag = ""
    
    init(listing: DesignListing? = nil) {
        self.listing = listing
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Images
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                                imagePreview(viewModel.selectedImages[index])
                            }
                            
                            if viewModel.selectedImages.count < 5 {
                                addImageButton
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Images")
                } footer: {
                    Text("Add up to 5 images of your design")
                }
                
                // Basic Info
                Section(header: Text("Basic Information")) {
                    TextField("Title", text: $viewModel.title)
                    
                    TextEditor(text: $viewModel.description)
                        .frame(height: 100)
                    
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(DesignListing.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    HStack {
                        TextField("Price", text: $viewModel.priceString)
                            .keyboardType(.decimalPad)
                        
                        Picker("Currency", selection: $viewModel.currency) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // Tags
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    viewModel.removeTag(tag)
                                }
                            }
                            
                            Button {
                                showingTagSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Add tags to help users find your design")
                }
                
                // Usage Rights
                Section {
                    Toggle("Commercial Use", isOn: $viewModel.allowsCommercialUse)
                    Toggle("Modifications", isOn: $viewModel.allowsModifications)
                } header: {
                    Text("Usage Rights")
                } footer: {
                    Text("Specify how buyers can use your design")
                }
            }
            .navigationTitle(listing == nil ? "Create Listing" : "Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveListing()
                            dismiss()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Post")
                                .bold()
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $viewModel.selectedPhotosItems,
                maxSelectionCount: 5,
                matching: .images
            )
            .sheet(isPresented: $showingTagSheet) {
                addTagSheet
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .task {
                if let listing = listing {
                    await viewModel.loadListing(listing)
                }
            }
        }
    }
    
    private func imagePreview(_ image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button {
                if let index = viewModel.selectedImages.firstIndex(of: image) {
                    viewModel.selectedImages.remove(at: index)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(4)
        }
    }
    
    private var addImageButton: some View {
        Button {
            showingImagePicker = true
        } label: {
            VStack {
                Image(systemName: "plus")
                    .font(.title)
                Text("Add Image")
                    .font(.caption)
            }
            .foregroundColor(.accentColor)
            .frame(width: 100, height: 100)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var addTagSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Enter tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(viewModel.suggestedTags, id: \.self) { tag in
                            Button {
                                viewModel.addTag(tag)
                            } label: {
                                Text(tag)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingTagSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if !newTag.isEmpty {
                            viewModel.addTag(newTag)
                            newTag = ""
                        }
                        showingTagSheet = false
                    } label: {
                        Text("Add")
                            .bold()
                    }
                    .disabled(newTag.isEmpty)
                }
            }
        }
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.subheadline)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    CreateListingView()
} 