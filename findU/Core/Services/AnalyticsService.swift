import Foundation
import Firebase
import FirebaseAnalytics

enum AnalyticsEvent {
    case screenView(screen: String)
    case userAction(action: String, parameters: [String: Any]?)
    case error(type: String, message: String)
    case performance(name: String, duration: TimeInterval)
    
    var name: String {
        switch self {
        case .screenView:
            return "screen_view"
        case .userAction:
            return "user_action"
        case .error:
            return "error"
        case .performance:
            return "performance"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .screenView(let screen):
            return ["screen_name": screen]
        case .userAction(let action, let params):
            var parameters = ["action": action]
            params?.forEach { parameters[$0.key] = $0.value }
            return parameters
        case .error(let type, let message):
            return [
                "error_type": type,
                "error_message": message
            ]
        case .performance(let name, let duration):
            return [
                "metric_name": name,
                "duration": duration
            ]
        }
    }
}

class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {
        setupAnalytics()
    }
    
    private func setupAnalytics() {
        FirebaseApp.configure()
    }
    
    // MARK: - Event Tracking
    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    // MARK: - Screen Tracking
    func trackScreen(_ screenName: String, className: String? = nil) {
        Analytics.logEvent(AnalyticsEvent.screenView(screen: screenName).name,
                         parameters: [
                            AnalyticsParameterScreenName: screenName,
                            AnalyticsParameterScreenClass: className ?? ""
                         ])
    }
    
    // MARK: - User Properties
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    // MARK: - Performance Monitoring
    private var traces: [String: Trace] = [:]
    
    func startTrace(name: String) {
        let trace = Performance.startTrace(name: name)
        traces[name] = trace
    }
    
    func stopTrace(name: String) {
        guard let trace = traces[name] else { return }
        trace.stop()
        traces.removeValue(forKey: name)
    }
    
    func incrementMetric(name: String, by value: Int = 1) {
        traces.values.forEach { $0.incrementMetric(name, by: value) }
    }
    
    // MARK: - Error Tracking
    func logError(_ error: Error, type: String) {
        let event = AnalyticsEvent.error(type: type, message: error.localizedDescription)
        logEvent(event)
    }
    
    // MARK: - Custom Metrics
    func trackCustomMetric(name: String, value: Double) {
        let event = AnalyticsEvent.performance(name: name, duration: value)
        logEvent(event)
    }
    
    // MARK: - User Engagement
    func trackEngagement(type: String, duration: TimeInterval) {
        let event = AnalyticsEvent.userAction(action: "engagement",
                                            parameters: [
                                                "type": type,
                                                "duration": duration
                                            ])
        logEvent(event)
    }
    
    // MARK: - Session Management
    func startSession() {
        setUserProperty("true", forName: "is_active")
        logEvent(AnalyticsEvent.userAction(action: "session_start", parameters: nil))
    }
    
    func endSession() {
        setUserProperty("false", forName: "is_active")
        logEvent(AnalyticsEvent.userAction(action: "session_end", parameters: nil))
    }
} 