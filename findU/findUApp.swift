import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct findUApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Load environment variables
        EnvironmentLoader.load()
        
        // Initialize other services here
        setupServices()
        
        FirebaseApp.configure()
    }
    
    private func setupServices() {
        do {
            // Example of using configuration
            let config = ConfigurationManager.shared
            
            // Verify critical configurations
            _ = try config.firebaseApiKey
            _ = try config.stripePublishableKey
            _ = try config.instagramClientId
            
            print("✅ All critical configurations verified")
        } catch {
            print("⚠️ Configuration error: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedTab: Tab = .home
    @Published var showingOnboarding = true
    
    enum Tab {
        case home
        case search
        case design
        case wishlist
        case profile
    }
} 