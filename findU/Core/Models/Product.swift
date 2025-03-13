import Foundation
import FirebaseFirestoreSwift

struct Product: Identifiable, Codable, Hashable {
    @DocumentID var id: UUID?
    let title: String
    let subtitle: String?
    let description: String
    let imageURLs: [String]
    let price: Double
    let currency: String
    let category: Category
    let subcategory: String?
    let brand: String?
    let size: String?
    let color: String?
    let material: String?
    let condition: Condition
    let tags: Set<String>
    let isFavorite: Bool
    let dateAdded: Date
    let lastModified: Date
    let sellerId: String
    
    enum Category: String, Codable, CaseIterable {
        case tops
        case bottoms
        case dresses
        case outerwear
        case shoes
        case accessories
        case other
    }
    
    enum Condition: String, Codable, CaseIterable {
        case new
        case likeNew = "like_new"
        case good
        case fair
        case poor
    }
    
    // MARK: - Computed Properties
    
    var mainImageURL: String? {
        imageURLs.first
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "\(currency) \(price)"
    }
    
    // MARK: - Initialization
    
    init(id: UUID = UUID(),
         title: String,
         subtitle: String? = nil,
         description: String,
         imageURLs: [String],
         price: Double,
         currency: String = "USD",
         category: Category,
         subcategory: String? = nil,
         brand: String? = nil,
         size: String? = nil,
         color: String? = nil,
         material: String? = nil,
         condition: Condition = .new,
         tags: Set<String> = [],
         isFavorite: Bool = false,
         dateAdded: Date = Date(),
         lastModified: Date = Date(),
         sellerId: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.imageURLs = imageURLs
        self.price = price
        self.currency = currency
        self.category = category
        self.subcategory = subcategory
        self.brand = brand
        self.size = size
        self.color = color
        self.material = material
        self.condition = condition
        self.tags = tags
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.lastModified = lastModified
        self.sellerId = sellerId
    }
}

// MARK: - Preview

#if DEBUG
extension Product {
    static var preview: Product {
        Product(
            title: "Vintage Denim Jacket",
            subtitle: "Classic Blue",
            description: "A timeless denim jacket in excellent condition",
            imageURLs: ["jacket_1", "jacket_2"],
            price: 89.99,
            category: .outerwear,
            brand: "Levi's",
            size: "M",
            color: "Blue",
            material: "100% Cotton",
            condition: .likeNew,
            tags: ["vintage", "denim", "casual"],
            sellerId: "user123"
        )
    }
    
    static var previewArray: [Product] {
        [
            preview,
            Product(
                title: "White T-Shirt",
                description: "Basic cotton t-shirt",
                imageURLs: ["tshirt_1"],
                price: 19.99,
                category: .tops,
                size: "L",
                color: "White",
                material: "Cotton",
                sellerId: "user123"
            ),
            Product(
                title: "Black Jeans",
                subtitle: "Slim Fit",
                description: "Classic black jeans",
                imageURLs: ["jeans_1"],
                price: 59.99,
                category: .bottoms,
                brand: "Gap",
                size: "32x32",
                color: "Black",
                material: "Denim",
                sellerId: "user123"
            )
        ]
    }
} 