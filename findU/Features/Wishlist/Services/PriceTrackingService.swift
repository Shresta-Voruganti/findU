import Foundation
import UserNotifications
import Firebase
import FirebaseFirestore

actor PriceTrackingService {
    private let db = Firestore.firestore()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    static let shared = PriceTrackingService()
    private init() {}
    
    // MARK: - Price Tracking
    
    func startPriceTracking() async throws {
        // Request notification permissions
        try await requestNotificationPermissions()
        
        // Start background price check task
        startBackgroundPriceCheck()
    }
    
    private func requestNotificationPermissions() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await notificationCenter.requestAuthorization(options: options)
    }
    
    private func startBackgroundPriceCheck() {
        Task {
            while true {
                await checkPrices()
                try await Task.sleep(nanoseconds: 3600 * 1_000_000_000) // Check every hour
            }
        }
    }
    
    private func checkPrices() async {
        do {
            let items = try await fetchItemsWithPriceAlerts()
            for item in items {
                if let currentPrice = try await fetchCurrentPrice(for: item),
                   let oldPrice = item.price {
                    try await updatePrice(for: item, newPrice: currentPrice)
                    
                    // Check if price drop notification should be triggered
                    if let alert = item.priceAlert,
                       item.notificationEnabled {
                        let threshold = oldPrice * (1 - alert.threshold / 100)
                        if currentPrice <= threshold {
                            await sendPriceDropNotification(for: item, oldPrice: oldPrice, newPrice: currentPrice)
                        }
                    }
                }
            }
        } catch {
            print("Error checking prices: \(error)")
        }
    }
    
    private func fetchItemsWithPriceAlerts() async throws -> [WishlistItem] {
        let snapshot = try await db.collection("wishlistItems")
            .whereField("notificationEnabled", isEqualTo: true)
            .getDocuments()
        
        return try snapshot.documents.map { doc in
            try Firestore.Decoder().decode(WishlistItem.self, from: doc.data())
        }
    }
    
    private func fetchCurrentPrice(for item: WishlistItem) async throws -> Double? {
        // Implement price fetching logic here
        // This could involve web scraping, API calls, etc.
        // For now, we'll return a random price for demonstration
        return item.price.map { $0 * Double.random(in: 0.8...1.2) }
    }
    
    private func updatePrice(for item: WishlistItem, newPrice: Double) async throws {
        let priceRecord = PriceRecord(date: Date(), price: newPrice)
        var updatedItem = item
        updatedItem.price = newPrice
        updatedItem.priceHistory = (updatedItem.priceHistory ?? []) + [priceRecord]
        updatedItem.updatedAt = Date()
        
        try await db.collection("wishlistItems")
            .document(item.id)
            .setData(from: updatedItem)
    }
    
    // MARK: - Notifications
    
    private func sendPriceDropNotification(for item: WishlistItem, oldPrice: Double, newPrice: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "Price Drop Alert! 🎉"
        content.body = """
            The price of "\(item.note ?? "your item")" has dropped from \
            $\(String(format: "%.2f", oldPrice)) to $\(String(format: "%.2f", newPrice))
            """
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "price-drop-\(item.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error sending notification: \(error)")
        }
    }
    
    // MARK: - Web Scraping
    
    private func scrapePriceFromWebsite(_ url: URL) async throws -> Double? {
        // Implement web scraping logic here
        // This would involve fetching the webpage and parsing it for price information
        return nil
    }
} 