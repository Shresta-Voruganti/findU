import Foundation

/// Loads environment variables from .env file
enum EnvironmentLoader {
    /// Loads environment variables from .env file
    static func load() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ .env file not found. Make sure to copy .env.template to .env and fill in the values.")
            return
        }
        
        do {
            let contents = try String(contentsOfFile: path, encoding: .utf8)
            
            let envVars = contents
                .split(separator: "\n")
                .filter { !$0.starts(with: "#") } // Skip comments
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } // Skip empty lines
                .map { String($0) }
            
            for envVar in envVars {
                let parts = envVar.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                
                let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                setenv(key, value, 1)
            }
            
            print("✅ Environment variables loaded successfully")
        } catch {
            print("⚠️ Error loading .env file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Usage Example
/*
 // Call this in your app's initialization (e.g., in AppDelegate or @main struct)
 EnvironmentLoader.load()
 */ 