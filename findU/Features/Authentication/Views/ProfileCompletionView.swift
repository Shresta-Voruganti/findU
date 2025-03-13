import SwiftUI

struct ProfileCompletionView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedInterests: Set<String> = []
    @State private var selectedCountry = ""
    @State private var currentStep = 0
    
    private let fashionInterests = [
        "Streetwear",
        "Minimalist",
        "Vintage",
        "Luxury",
        "Casual",
        "Formal",
        "Athleisure",
        "Bohemian",
        "Preppy",
        "Avant-garde",
        "Sustainable",
        "Accessories",
        "Footwear",
        "Denim",
        "Activewear"
    ]
    
    private let countries = [
        "United States",
        "United Kingdom",
        "Canada",
        "Australia",
        "India",
        "Japan",
        "South Korea",
        "Singapore",
        "Germany",
        "France",
        "Italy",
        "Spain",
        "Brazil",
        "Mexico"
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $currentStep) {
                    // Fashion Interests
                    VStack(spacing: 20) {
                        Text("What's your fashion style?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select all that interest you")
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(fashionInterests, id: \.self) { interest in
                                    InterestButton(
                                        title: interest,
                                        isSelected: selectedInterests.contains(interest)
                                    ) {
                                        if selectedInterests.contains(interest) {
                                            selectedInterests.remove(interest)
                                        } else {
                                            selectedInterests.insert(interest)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .tag(0)
                    
                    // Region Selection
                    VStack(spacing: 20) {
                        Text("Where are you located?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("This helps us show relevant products and prices")
                            .foregroundColor(.secondary)
                        
                        List(countries, id: \.self) { country in
                            Button(action: {
                                selectedCountry = country
                            }) {
                                HStack {
                                    Text(country)
                                    Spacer()
                                    if country == selectedCountry {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if currentStep < 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .disabled(selectedInterests.isEmpty)
                    } else {
                        Button("Complete") {
                            completeProfile()
                        }
                        .disabled(selectedCountry.isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func completeProfile() {
        Task {
            do {
                let region = Region(
                    country: selectedCountry,
                    countryCode: "US", // This should be mapped from the country
                    currency: "USD", // This should be mapped from the country
                    supportedPlatforms: [.myntra, .hm, .asos] // This should be mapped from the country
                )
                
                try await viewModel.completeProfile(
                    fashionInterests: Array(selectedInterests),
                    region: region
                )
                
                dismiss()
            } catch {
                // Error is already handled by the view model
            }
        }
    }
}

struct InterestButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

#Preview {
    ProfileCompletionView(viewModel: AuthenticationViewModel())
} 