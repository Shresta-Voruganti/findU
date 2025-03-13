import Foundation
import Vision
import CoreML
import UIKit
import FirebaseStorage
import FirebaseFirestore

actor ImageSearchService {
    static let shared = ImageSearchService()
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private var searchCache: [String: [SearchResult]] = [:]
    
    private init() {}
    
    // MARK: - Image Search
    
    func searchOutfits(with image: UIImage) async throws -> [SearchResult] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SearchError.invalidImageData
        }
        
        // Generate a unique ID for this search
        let searchId = UUID().uuidString
        
        // Upload image to temporary storage for processing
        let imageRef = storage.reference().child("search_images/\(searchId).jpg")
        _ = try await imageRef.putDataAsync(imageData)
        let imageUrl = try await imageRef.downloadURL()
        
        // Extract features from the image
        let features = try await extractImageFeatures(from: image)
        
        // Search for similar outfits
        let results = try await findSimilarOutfits(features: features)
        
        // Cache results
        searchCache[searchId] = results
        
        // Clean up temporary image after 24 hours
        Task {
            try? await Task.sleep(nanoseconds: 86400 * 1_000_000_000) // 24 hours
            try? await imageRef.delete()
            searchCache.removeValue(forKey: searchId)
        }
        
        return results
    }
    
    // MARK: - Feature Extraction
    
    private func extractImageFeatures(from image: UIImage) async throws -> [String: Any] {
        guard let cgImage = image.cgImage else {
            throw SearchError.invalidImageData
        }
        
        // Create a request to analyze the image
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        
        // Perform the request
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        // Extract features
        var features: [String: Any] = [:]
        
        // Add text recognition results
        if let results = request.results {
            let recognizedText = results.compactMap { result in
                (try? result.topCandidates(1).first?.string) ?? ""
            }
            features["text"] = recognizedText
        }
        
        // Add color analysis
        features["colors"] = try await analyzeColors(in: image)
        
        // Add object detection (clothing items)
        features["objects"] = try await detectClothingItems(in: image)
        
        return features
    }
    
    private func analyzeColors(in image: UIImage) async throws -> [[String: Any]] {
        // Implement color analysis using Core Image
        // This is a placeholder implementation
        return []
    }
    
    private func detectClothingItems(in image: UIImage) async throws -> [[String: Any]] {
        // Implement clothing item detection using Vision/CoreML
        // This is a placeholder implementation
        return []
    }
    
    // MARK: - Similarity Search
    
    private func findSimilarOutfits(features: [String: Any]) async throws -> [SearchResult] {
        // Query Firestore for similar outfits based on extracted features
        let query = db.collection("outfits")
            .limit(to: 20)
        
        let snapshot = try await query.getDocuments()
        
        return try snapshot.documents.compactMap { document -> SearchResult? in
            let data = document.data()
            
            guard let title = data["title"] as? String,
                  let imageUrl = data["imageUrl"] as? String,
                  let price = data["price"] as? Double,
                  let brand = data["brand"] as? String else {
                return nil
            }
            
            return SearchResult(
                id: document.documentID,
                title: title,
                imageUrl: imageUrl,
                price: price,
                brand: brand,
                similarity: calculateSimilarity(features: features, outfitFeatures: data)
            )
        }.sorted { $0.similarity > $1.similarity }
    }
    
    private func calculateSimilarity(features: [String: Any], outfitFeatures: [String: Any]) -> Double {
        // Implement similarity calculation based on features
        // This is a placeholder implementation
        return Double.random(in: 0.5...1.0)
    }
}

// MARK: - Models

struct SearchResult: Identifiable {
    let id: String
    let title: String
    let imageUrl: String
    let price: Double
    let brand: String
    let similarity: Double
}

enum SearchError: LocalizedError {
    case invalidImageData
    case featureExtractionFailed
    case searchFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Could not process the image"
        case .featureExtractionFailed:
            return "Failed to analyze the image"
        case .searchFailed:
            return "Failed to search for similar outfits"
        }
    }
} 