import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case network(NetworkError)
    case storage(StorageError)
    case validation(String)
    case authentication(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Network Error: \(error.localizedDescription)"
        case .storage(let error):
            return "Storage Error: \(error.localizedDescription)"
        case .validation(let message):
            return "Validation Error: \(message)"
        case .authentication(let message):
            return "Authentication Error: \(message)"
        case .unknown(let error):
            return "Unknown Error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network:
            return "Please check your internet connection and try again."
        case .storage:
            return "Please restart the app and try again."
        case .validation:
            return "Please check your input and try again."
        case .authentication:
            return "Please sign in again."
        case .unknown:
            return "Please try again later."
        }
    }
}

class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: AppError?
    @Published var showError = false
    
    private init() {}
    
    // MARK: - Error Handling
    func handle(_ error: Error) {
        let appError: AppError
        
        switch error {
        case let networkError as NetworkError:
            appError = .network(networkError)
        case let storageError as StorageError:
            appError = .storage(storageError)
        case let appError as AppError:
            appError = appError
        default:
            appError = .unknown(error)
        }
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.showError = true
        }
        
        // Log error to analytics
        AnalyticsService.shared.logError(error, type: String(describing: type(of: error)))
    }
    
    // MARK: - User Feedback
    func showErrorAlert(title: String = "Error",
                       message: String,
                       primaryButton: Alert.Button = .default(Text("OK")),
                       secondaryButton: Alert.Button? = nil) {
        DispatchQueue.main.async {
            self.currentError = AppError.validation(message)
            self.showError = true
        }
    }
    
    // MARK: - Error Recovery
    func attemptRecovery(from error: AppError) async -> Bool {
        switch error {
        case .network:
            // Attempt to reconnect or refresh token
            return await attemptNetworkRecovery()
        case .storage:
            // Attempt to clear cache and reload data
            return attemptStorageRecovery()
        case .authentication:
            // Attempt to refresh authentication
            return await attemptAuthenticationRecovery()
        default:
            return false
        }
    }
    
    private func attemptNetworkRecovery() async -> Bool {
        // Implement network recovery logic
        return false
    }
    
    private func attemptStorageRecovery() -> Bool {
        StorageService.shared.clearCache()
        return true
    }
    
    private func attemptAuthenticationRecovery() async -> Bool {
        // Implement authentication recovery logic
        return false
    }
    
    // MARK: - Error Prevention
    func validateInput(_ value: String, type: InputType) -> ValidationResult {
        switch type {
        case .email:
            return validateEmail(value)
        case .password:
            return validatePassword(value)
        case .username:
            return validateUsername(value)
        }
    }
    
    enum InputType {
        case email
        case password
        case username
    }
    
    enum ValidationResult {
        case valid
        case invalid(String)
    }
    
    private func validateEmail(_ email: String) -> ValidationResult {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email) ? .valid : .invalid("Invalid email format")
    }
    
    private func validatePassword(_ password: String) -> ValidationResult {
        guard password.count >= 8 else {
            return .invalid("Password must be at least 8 characters")
        }
        return .valid
    }
    
    private func validateUsername(_ username: String) -> ValidationResult {
        guard username.count >= 3 else {
            return .invalid("Username must be at least 3 characters")
        }
        return .valid
    }
}

// MARK: - View Extension for Error Handling
extension View {
    func handleError(_ errorHandler: ErrorHandlingService) -> some View {
        self.alert(isPresented: $errorHandler.showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorHandler.currentError?.errorDescription ?? "Unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    errorHandler.showError = false
                    errorHandler.currentError = nil
                }
            )
        }
    }
} 