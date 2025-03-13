import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(String)
    case unauthorized
    case noInternet
    case custom(String)
}

class NetworkService {
    static let shared = NetworkService()
    private let session: URLSession
    private let baseURL = "https://api.findu.com/v1" // Replace with actual API base URL
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    func request<T: Codable>(_ endpoint: String,
                            method: String = "GET",
                            parameters: [String: Any]? = nil,
                            headers: [String: String]? = nil) -> AnyPublisher<T, NetworkError> {
        
        guard var components = URLComponents(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        if method == "GET", let parameters = parameters {
            components.queryItems = parameters.map { 
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
        
        guard let url = components.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add default headers
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Add custom headers
        if let headers = headers {
            defaultHeaders.merge(headers) { (_, new) in new }
        }
        
        defaultHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Add body for non-GET requests
        if method != "GET", let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
            }
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw NetworkError.unauthorized
                case 400...499:
                    throw NetworkError.serverError("Client Error: \(httpResponse.statusCode)")
                case 500...599:
                    throw NetworkError.serverError("Server Error: \(httpResponse.statusCode)")
                default:
                    throw NetworkError.serverError("Unknown Error: \(httpResponse.statusCode)")
                }
            }
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                return NetworkError.custom(error.localizedDescription)
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> NetworkError in
                if error is DecodingError {
                    return NetworkError.decodingError
                }
                return error as? NetworkError ?? NetworkError.custom(error.localizedDescription)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // Convenience methods for common HTTP methods
    func get<T: Codable>(_ endpoint: String,
                         parameters: [String: Any]? = nil,
                         headers: [String: String]? = nil) -> AnyPublisher<T, NetworkError> {
        return request(endpoint, method: "GET", parameters: parameters, headers: headers)
    }
    
    func post<T: Codable>(_ endpoint: String,
                          parameters: [String: Any]? = nil,
                          headers: [String: String]? = nil) -> AnyPublisher<T, NetworkError> {
        return request(endpoint, method: "POST", parameters: parameters, headers: headers)
    }
    
    func put<T: Codable>(_ endpoint: String,
                         parameters: [String: Any]? = nil,
                         headers: [String: String]? = nil) -> AnyPublisher<T, NetworkError> {
        return request(endpoint, method: "PUT", parameters: parameters, headers: headers)
    }
    
    func delete<T: Codable>(_ endpoint: String,
                           parameters: [String: Any]? = nil,
                           headers: [String: String]? = nil) -> AnyPublisher<T, NetworkError> {
        return request(endpoint, method: "DELETE", parameters: parameters, headers: headers)
    }
} 