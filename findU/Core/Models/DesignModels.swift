import SwiftUI
import FirebaseFirestoreSwift

// MARK: - Design Model
struct Design: Identifiable, Codable {
    @DocumentID var id: String?
    let creatorId: String
    var title: String
    var description: String
    var category: Category
    var style: [Style]
    var tags: [String]
    var imageUrls: [String]
    var thumbnailUrl: String?
    var price: Double?
    var isPublished: Bool
    var isForSale: Bool
    var createdAt: Date
    var updatedAt: Date
    var stats: DesignStats
    
    enum Category: String, Codable, CaseIterable {
        case casual = "Casual"
        case formal = "Formal"
        case streetwear = "Streetwear"
        case athletic = "Athletic"
        case business = "Business"
        case evening = "Evening"
        case custom = "Custom"
    }
    
    enum Style: String, Codable, CaseIterable {
        case minimalist = "Minimalist"
        case vintage = "Vintage"
        case modern = "Modern"
        case bohemian = "Bohemian"
        case preppy = "Preppy"
        case grunge = "Grunge"
        case classic = "Classic"
        case edgy = "Edgy"
    }
}

// MARK: - Design Canvas
struct DesignCanvas: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var size: CGSize
    var items: [DesignItem]
    var background: CanvasBackground
    var createdAt: Date
    var updatedAt: Date
    var version: Int
    var creatorId: String?
    var isPublished: Bool
    var category: Design.Category
    var tags: [String]
    var stats: DesignStats
    
    init(
        id: String? = nil,
        name: String = "Untitled Design",
        size: CGSize = CGSize(width: 414, height: 896),
        items: [DesignItem] = [],
        background: CanvasBackground = .solid(color: .white),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        version: Int = 1,
        creatorId: String? = nil,
        isPublished: Bool = false,
        category: Design.Category = .custom,
        tags: [String] = [],
        stats: DesignStats = DesignStats()
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.items = items
        self.background = background
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.creatorId = creatorId
        self.isPublished = isPublished
        self.category = category
        self.tags = tags
        self.stats = stats
    }
}

// MARK: - Design Item
struct DesignItem: Identifiable, Codable, Equatable {
    let id: UUID
    var type: ItemType
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    var opacity: Double
    var zIndex: Int
    var isLocked: Bool
    var properties: ItemProperties
    
    enum ItemType: String, Codable {
        case text
        case image
        case shape
        case garment
        case pattern
        case accessory
    }
}

// MARK: - Item Properties
struct ItemProperties: Codable, Equatable {
    // Common properties
    var backgroundColor: Color?
    var borderColor: Color?
    var borderWidth: CGFloat?
    
    // Text specific
    var text: String?
    var fontName: String?
    var fontSize: CGFloat?
    var textColor: Color?
    var alignment: TextAlignment?
    
    // Image/Pattern specific
    var imageUrl: String?
    var contentMode: ContentMode?
    var tileMode: TileMode?
    var scale: CGFloat?
    
    // Shape specific
    var shapeType: ShapeType?
    var fillColor: Color?
    
    // Garment specific
    var garmentType: GarmentType?
    var size: ClothingSize?
    var fabricType: FabricType?
    
    enum ShapeType: String, Codable {
        case rectangle, circle, triangle, polygon, star, custom
    }
    
    enum TileMode: String, Codable {
        case none, repeat, mirror, repeatX, repeatY
    }
    
    enum GarmentType: String, Codable {
        case shirt, pants, dress, skirt, jacket, accessory
    }
    
    enum FabricType: String, Codable {
        case cotton, silk, wool, leather, denim, synthetic
    }
    
    enum ClothingSize: String, Codable {
        case XS, S, M, L, XL, XXL, custom
    }
}

// MARK: - Canvas Background
enum CanvasBackground: Codable, Equatable {
    case solid(color: Color)
    case gradient(colors: [Color], angle: Double)
    case image(url: String)
    case pattern(type: PatternType, colors: [Color])
    
    enum PatternType: String, Codable {
        case dots, stripes, checks, herringbone, none
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, color, colors, angle, url, patternType
    }
    
    private enum BackgroundType: String, Codable {
        case solid, gradient, image, pattern
    }
}

// MARK: - Design Template
struct DesignTemplate: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: TemplateCategory
    var previewUrl: String
    var canvas: DesignCanvas
    var tags: [String]
    var isCustom: Bool
    
    enum TemplateCategory: String, Codable {
        case casual, formal, sportswear, streetwear, ethnic, custom
    }
}

// MARK: - Design Version
struct DesignVersion: Identifiable, Codable {
    @DocumentID var id: String?
    let designId: String
    let version: Int
    let canvas: DesignCanvas
    let timestamp: Date
    let authorId: String
    var comment: String?
}

// MARK: - Design Stats
struct DesignStats: Codable, Equatable {
    var views: Int = 0
    var likes: Int = 0
    var shares: Int = 0
    var saves: Int = 0
    var comments: Int = 0
}

// MARK: - Design Categories
extension Design {
    enum Category: String, Codable, CaseIterable {
        case casual = "Casual"
        case formal = "Formal"
        case streetwear = "Streetwear"
        case athletic = "Athletic"
        case business = "Business"
        case evening = "Evening"
        case custom = "Custom"
    }
}

// MARK: - Extensions for SwiftUI Types
extension Color: Codable {
    private struct Components {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
    }
    
    private enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    private var components: Components {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Components(red: Double(red),
                        green: Double(green),
                        blue: Double(blue),
                        alpha: Double(alpha))
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let components = self.components
        try container.encode(components.red, forKey: .red)
        try container.encode(components.green, forKey: .green)
        try container.encode(components.blue, forKey: .blue)
        try container.encode(components.alpha, forKey: .alpha)
    }
}

extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        self.init(x: x, y: y)
    }
}

extension CGSize: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let width = try container.decode(Double.self)
        let height = try container.decode(Double.self)
        self.init(width: width, height: height)
    }
}

extension TextAlignment: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "leading": self = .leading
        case "center": self = .center
        case "trailing": self = .trailing
        default: self = .leading
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .leading: try container.encode("leading")
        case .center: try container.encode("center")
        case .trailing: try container.encode("trailing")
        }
    }
}

extension ContentMode: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "fill": self = .fill
        case "fit": self = .fit
        default: self = .fit
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fill: try container.encode("fill")
        case .fit: try container.encode("fit")
        }
    }
} 
} 