import Foundation

enum AppConfig {
    // MARK: - API Keys and Endpoints
    enum API {
        static let stripePublishableKey = "YOUR_STRIPE_PUBLISHABLE_KEY"
        static let instagramClientId = "YOUR_INSTAGRAM_CLIENT_ID"
        static let instagramClientSecret = "YOUR_INSTAGRAM_CLIENT_SECRET"
        static let instagramRedirectUri = "findU://instagram-oauth"
        
        static let baseUrl = "https://api.findu.com" // Replace with your actual API base URL
        static let termsUrl = "https://findu.com/terms"
        static let privacyUrl = "https://findu.com/privacy"
    }
    
    // MARK: - App Settings
    enum Settings {
        static let minimumPasswordLength = 8
        static let maximumUsernameLength = 30
        static let maximumBioLength = 150
        static let maximumListingImages = 5
        static let maximumListingPrice = 10000.0
        static let platformFeePercentage = 0.10 // 10%
        
        static let defaultCurrency = "USD"
        static let supportedCurrencies = ["USD", "EUR", "GBP"]
        
        static let defaultImageQuality: CGFloat = 0.8
        static let maximumImageSize = 5 * 1024 * 1024 // 5MB
    }
    
    // MARK: - Design Categories
    static let designCategories: [DesignListing.Category] = [
        .outfit,
        .collection,
        .accessory,
        .custom
    ]
    
    // MARK: - Style Tags
    static let defaultStyleTags = [
        "Casual",
        "Formal",
        "Streetwear",
        "Vintage",
        "Minimalist",
        "Bohemian",
        "Athletic",
        "Business",
        "Party",
        "Beach",
        "Festival",
        "Wedding",
        "Sustainable",
        "Handmade",
        "Limited Edition",
        "Custom"
    ]
    
    // MARK: - Cache Settings
    enum Cache {
        static let maximumMemorySize = 50 * 1024 * 1024 // 50MB
        static let maximumDiskSize = 100 * 1024 * 1024 // 100MB
        static let timeToLive: TimeInterval = 7 * 24 * 60 * 60 // 1 week
    }
    
    // MARK: - Error Messages
    enum ErrorMessages {
        static let genericError = "Something went wrong. Please try again."
        static let networkError = "Please check your internet connection and try again."
        static let authenticationError = "Invalid email or password."
        static let validationError = "Please check your input and try again."
        static let uploadError = "Failed to upload image. Please try again."
        static let paymentError = "Payment processing failed. Please try again."
        static let instagramError = "Failed to connect to Instagram. Please try again."
    }
    
    // MARK: - Validation Rules
    enum Validation {
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        static let usernameRegex = "^[a-zA-Z0-9._-]{3,30}$"
        static let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
    }
    
    // MARK: - UI Constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 5
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
        
        static let primaryColor = "AccentColor" // Asset name
        static let secondaryColor = "SecondaryColor"
        static let backgroundColor = "BackgroundColor"
        
        static let defaultAnimationDuration: Double = 0.3
        static let longAnimationDuration: Double = 0.5
    }
    
    // MARK: - Feature Flags
    enum FeatureFlags {
        static let enableInstagramIntegration = true
        static let enableStripePayments = true
        static let enablePushNotifications = true
        static let enableAnalytics = true
        static let enableCrashReporting = true
        static let enableBetaFeatures = false
    }
}

// MARK: - Environment
extension AppConfig {
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            if Bundle.main.bundleIdentifier?.contains("staging") == true {
                return .staging
            }
            return .production
            #endif
        }
    }
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var apiBaseUrl: String {
        switch Environment.current {
        case .development:
            return "https://dev-api.findu.com"
        case .staging:
            return "https://staging-api.findu.com"
        case .production:
            return "https://api.findu.com"
        }
    }
} 