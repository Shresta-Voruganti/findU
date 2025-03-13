import SwiftUI
import FirebaseFirestoreSwift

struct DesignCanvas: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var size: CGSize
    var items: [DesignItem]
    var background: CanvasBackground
    let createdAt: Date
    var updatedAt: Date
    var version: Int
    var metadata: [String: String]?
    
    init(id: String? = nil,
         name: String,
         size: CGSize,
         items: [DesignItem] = [],
         background: CanvasBackground = .solid(color: .white),
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         version: Int = 1,
         metadata: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.size = size
        self.items = items
        self.background = background
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.metadata = metadata
    }
}

// MARK: - Background Types

enum CanvasBackground: Codable, Equatable {
    case solid(color: Color)
    case gradient(colors: [Color], angle: Double)
    case image(url: String)
    case pattern(type: PatternType, colors: [Color])
    
    enum PatternType: String, Codable {
        case dots
        case stripes
        case checks
        case herringbone
        case none
    }
    
    var color: Color {
        switch self {
        case .solid(let color):
            return color
        case .gradient(let colors, _):
            return colors.first ?? .white
        case .image:
            return .white
        case .pattern(_, let colors):
            return colors.first ?? .white
        }
    }
    
    // MARK: - Coding
    
    private enum CodingKeys: String, CodingKey {
        case type, color, colors, angle, url, patternType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "solid":
            let colorHex = try container.decode(String.self, forKey: .color)
            self = .solid(color: Color(hex: colorHex) ?? .white)
            
        case "gradient":
            let colorHexes = try container.decode([String].self, forKey: .colors)
            let colors = colorHexes.compactMap { Color(hex: $0) }
            let angle = try container.decode(Double.self, forKey: .angle)
            self = .gradient(colors: colors, angle: angle)
            
        case "image":
            let url = try container.decode(String.self, forKey: .url)
            self = .image(url: url)
            
        case "pattern":
            let patternType = try container.decode(PatternType.self, forKey: .patternType)
            let colorHexes = try container.decode([String].self, forKey: .colors)
            let colors = colorHexes.compactMap { Color(hex: $0) }
            self = .pattern(type: patternType, colors: colors)
            
        default:
            self = .solid(color: .white)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .solid(let color):
            try container.encode("solid", forKey: .type)
            try container.encode(color.toHex(), forKey: .color)
            
        case .gradient(let colors, let angle):
            try container.encode("gradient", forKey: .type)
            try container.encode(colors.map { $0.toHex() }, forKey: .colors)
            try container.encode(angle, forKey: .angle)
            
        case .image(let url):
            try container.encode("image", forKey: .type)
            try container.encode(url, forKey: .url)
            
        case .pattern(let type, let colors):
            try container.encode("pattern", forKey: .type)
            try container.encode(type, forKey: .patternType)
            try container.encode(colors.map { $0.toHex() }, forKey: .colors)
        }
    }
}

// MARK: - Size Coding

extension CGSize: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height
    }
}

// MARK: - Preview

#if DEBUG
extension DesignCanvas {
    static var preview: DesignCanvas {
        DesignCanvas(
            name: "Sample Design",
            size: CGSize(width: 1024, height: 1024),
            items: [
                DesignItem.preview,
                DesignItem.previewText
            ],
            background: .gradient(
                colors: [.blue, .purple],
                angle: 45
            ),
            metadata: [
                "creator": "user123",
                "template": "basic"
            ]
        )
    }
} 