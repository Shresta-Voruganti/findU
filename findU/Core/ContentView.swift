import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        Group {
            if appState.showingOnboarding {
                OnboardingView()
            } else if !authViewModel.isAuthenticated {
                AuthenticationView(viewModel: authViewModel)
            } else {
                MainTabView()
            }
        }
        .environmentObject(appState)
        .environmentObject(authViewModel)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingImageSearch = false
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)
            
            MarketplaceView()
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(AppTab.marketplace)
            
            // Camera Button (Image Search)
            Button(action: {
                showingImageSearch = true
            }) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .offset(y: -20)
            .tabItem {
                Label("Search", systemImage: "camera.fill")
            }
            .tag(AppTab.search)
            
            OutfitDesignView()
                .tabItem {
                    Label("Design", systemImage: "scissors")
                }
                .tag(AppTab.design)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .sheet(isPresented: $showingImageSearch) {
            ImageSearchView()
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var showingOnboarding = true
    @Published var selectedTab: AppTab = .home
    @Published var showingProfileCompletion = false
}

enum AppTab {
    case home
    case marketplace
    case search
    case design
    case profile
}

// MARK: - Preview

#Preview {
    ContentView()
} 