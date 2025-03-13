import Foundation

/// Errors that can occur when accessing configuration values
enum ConfigurationError: LocalizedError {
    case missingKey(String)
    case invalidValue(String)
    
    var errorDescription: String? {
        switch self {
        case .missingKey(let key):
            return "Missing environment variable: \(key). Ensure you have copied .env.template to .env and filled in all values."
        case .invalidValue(let key):
            return "Invalid value for environment variable: \(key). Please check your .env file."
        }
    }
}

/// Manages access to environment-based configuration values
final class ConfigurationManager {
    /// Shared instance for singleton access
    static let shared = ConfigurationManager()
    
    private init() {
        // Verify environment setup on initialization
        verifyEnvironmentSetup()
    }
    
    /// Verifies that critical environment variables are present
    private func verifyEnvironmentSetup() {
        #if DEBUG
        let requiredKeys = [
            "FIREBASE_API_KEY",
            "STRIPE_PUBLISHABLE_KEY",
            "INSTAGRAM_CLIENT_ID"
        ]
        
        let missingKeys = requiredKeys.filter { ProcessInfo.processInfo.environment[$0] == nil }
        if !missingKeys.isEmpty {
            print("⚠️ Warning: Missing required environment variables: \(missingKeys.joined(separator: ", "))")
            print("💡 Tip: Make sure you have:")
            print("1. Copied .env.template to .env")
            print("2. Filled in all values in .env")
            print("3. Properly loaded the environment variables")
        }
        #endif
    }
    
    /// Gets a configuration value for the specified key
    /// - Parameter key: The environment variable key
    /// - Returns: The value for the specified key
    /// - Throws: ConfigurationError if the key is missing or invalid
    func getValue(for key: String) throws -> String {
        guard let value = ProcessInfo.processInfo.environment[key] else {
            throw ConfigurationError.missingKey(key)
        }
        
        if value.isEmpty || value.contains("your_") || value.contains("replace_with_") {
            throw ConfigurationError.invalidValue(key)
        }
        
        return value
    }
    
    // MARK: - Firebase Configuration
    
    var firebaseApiKey: String {
        get throws { try getValue(for: "FIREBASE_API_KEY") }
    }
    
    var firebaseAuthDomain: String {
        get throws { try getValue(for: "FIREBASE_AUTH_DOMAIN") }
    }
    
    var firebaseProjectId: String {
        get throws { try getValue(for: "FIREBASE_PROJECT_ID") }
    }
    
    var firebaseStorageBucket: String {
        get throws { try getValue(for: "FIREBASE_STORAGE_BUCKET") }
    }
    
    var firebaseMessagingSenderId: String {
        get throws { try getValue(for: "FIREBASE_MESSAGING_SENDER_ID") }
    }
    
    var firebaseAppId: String {
        get throws { try getValue(for: "FIREBASE_APP_ID") }
    }
    
    // MARK: - Stripe Configuration
    
    var stripePublishableKey: String {
        get throws { try getValue(for: "STRIPE_PUBLISHABLE_KEY") }
    }
    
    var stripeSecretKey: String {
        get throws { try getValue(for: "STRIPE_SECRET_KEY") }
    }
    
    // MARK: - Instagram Configuration
    
    var instagramClientId: String {
        get throws { try getValue(for: "INSTAGRAM_CLIENT_ID") }
    }
    
    var instagramClientSecret: String {
        get throws { try getValue(for: "INSTAGRAM_CLIENT_SECRET") }
    }
    
    var instagramRedirectUri: String {
        get throws { try getValue(for: "INSTAGRAM_REDIRECT_URI") }
    }
    
    // MARK: - API Configuration
    
    var apiBaseUrl: String {
        get throws { try getValue(for: "API_BASE_URL") }
    }
    
    var apiVersion: String {
        get throws { try getValue(for: "API_VERSION") }
    }
    
    // MARK: - Environment
    
    var environment: String {
        get throws { try getValue(for: "ENVIRONMENT") }
    }
    
    var isProduction: Bool {
        (try? environment == "production") ?? false
    }
}

// MARK: - Usage Example
/*
 do {
     let config = ConfigurationManager.shared
     let stripeKey = try config.stripePublishableKey
     // Use the key...
 } catch {
     print("Configuration error: \(error.localizedDescription)")
 }
 */ 