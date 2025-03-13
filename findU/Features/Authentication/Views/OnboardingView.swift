import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to findU",
            description: "Your personal fashion assistant for discovering, creating, and sharing amazing outfits.",
            imageName: "onboarding1"
        ),
        OnboardingPage(
            title: "Discover Your Style",
            description: "Search for outfits by image, save inspiration, and get personalized recommendations.",
            imageName: "onboarding2"
        ),
        OnboardingPage(
            title: "Create & Share",
            description: "Design outfits, share your style, and connect with fashion enthusiasts worldwide.",
            imageName: "onboarding3"
        )
    ]
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                if currentPage == pages.count - 1 {
                    Button(action: {
                        withAnimation {
                            appState.showingOnboarding = false
                        }
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        withAnimation {
                            appState.showingOnboarding = false
                        }
                    }) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.bottom, 50)
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .padding()
            
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
} 