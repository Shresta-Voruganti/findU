import SwiftUI

struct Pattern: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let type: PatternType
    let colors: [Color]
    let scale: Double
    let rotation: Double
    let category: Category
    let tags: Set<String>
    let previewURL: String?
    let dateAdded: Date
    let isCustom: Bool
    
    enum PatternType: String, Codable, CaseIterable {
        case dots
        case stripes
        case checks
        case herringbone
        case floral
        case geometric
        case abstract
        case custom
        
        var defaultScale: Double {
            switch self {
            case .dots: return 20
            case .stripes: return 30
            case .checks: return 40
            case .herringbone: return 25
            case .floral: return 100
            case .geometric: return 50
            case .abstract: return 100
            case .custom: return 50
            }
        }
    }
    
    enum Category: String, Codable, CaseIterable {
        case basic
        case nature
        case geometric
        case abstract
        case custom
    }
    
    init(id: UUID = UUID(),
         name: String,
         type: PatternType,
         colors: [Color],
         scale: Double? = nil,
         rotation: Double = 0,
         category: Category,
         tags: Set<String> = [],
         previewURL: String? = nil,
         dateAdded: Date = Date(),
         isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.colors = colors
        self.scale = scale ?? type.defaultScale
        self.rotation = rotation
        self.category = category
        self.tags = tags
        self.previewURL = previewURL
        self.dateAdded = dateAdded
        self.isCustom = isCustom
    }
}

// MARK: - Color Coding

extension Pattern {
    private enum CodingKeys: String, CodingKey {
        case id, name, type, colorHexValues, scale, rotation, category, tags, previewURL, dateAdded, isCustom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(PatternType.self, forKey: .type)
        let hexValues = try container.decode([String].self, forKey: .colorHexValues)
        colors = hexValues.compactMap { Color(hex: $0) }
        scale = try container.decode(Double.self, forKey: .scale)
        rotation = try container.decode(Double.self, forKey: .rotation)
        category = try container.decode(Category.self, forKey: .category)
        tags = try container.decode(Set<String>.self, forKey: .tags)
        previewURL = try container.decodeIfPresent(String.self, forKey: .previewURL)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        isCustom = try container.decode(Bool.self, forKey: .isCustom)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        let hexValues = colors.map { $0.toHex() }
        try container.encode(hexValues, forKey: .colorHexValues)
        try container.encode(scale, forKey: .scale)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(category, forKey: .category)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(previewURL, forKey: .previewURL)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(isCustom, forKey: .isCustom)
    }
}

// MARK: - Preview

#if DEBUG
extension Pattern {
    static var preview: Pattern {
        Pattern(
            name: "Classic Polka Dots",
            type: .dots,
            colors: [.white, .black],
            category: .basic,
            tags: ["dots", "classic", "monochrome"]
        )
    }
    
    static var previewArray: [Pattern] {
        [
            preview,
            Pattern(
                name: "Navy Stripes",
                type: .stripes,
                colors: [.white, Color(hex: "1B365D")],
                category: .basic,
                tags: ["stripes", "nautical"]
            ),
            Pattern(
                name: "Spring Floral",
                type: .floral,
                colors: [.white, .pink, .green],
                category: .nature,
                tags: ["floral", "spring", "colorful"]
            ),
            Pattern(
                name: "Modern Geometric",
                type: .geometric,
                colors: [.white, .blue, .purple],
                category: .geometric,
                tags: ["geometric", "modern"]
            )
        ]
    }
} 