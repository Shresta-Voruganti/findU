import SwiftUI

struct DesignItem: Identifiable, Codable, CanvasItem {
    let id: UUID
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    var opacity: Double
    var zIndex: Int
    var isLocked: Bool
    let type: ItemType
    var properties: ElementProperties
    
    enum ItemType: String, Codable {
        case garment
        case pattern
        case text
        case shape
    }
    
    init(id: UUID = UUID(),
         type: ItemType,
         position: CGPoint,
         size: CGSize,
         rotation: Double = 0,
         opacity: Double = 1,
         zIndex: Int = 0,
         isLocked: Bool = false,
         properties: ElementProperties) {
        self.id = id
        self.type = type
        self.position = position
        self.size = size
        self.rotation = rotation
        self.opacity = opacity
        self.zIndex = zIndex
        self.isLocked = isLocked
        self.properties = properties
    }
}

struct ElementProperties: Codable {
    // Common properties
    var color: Color?
    var borderColor: Color?
    var borderWidth: Double?
    var cornerRadius: Double?
    
    // Text properties
    var text: String?
    var textStyle: TextStyle?
    
    // Garment properties
    var garmentType: GarmentType?
    var garmentColor: Color?
    var garmentPattern: Pattern?
    
    // Pattern properties
    var pattern: Pattern?
    
    // Shape properties
    var shapeType: ShapeType?
    
    enum GarmentType: String, Codable, CaseIterable {
        case shirt
        case pants
        case dress
        case jacket
        case skirt
        case shoes
        case accessory
    }
    
    enum ShapeType: String, Codable, CaseIterable {
        case rectangle
        case circle
        case triangle
        case star
        case heart
        case custom
    }
    
    // MARK: - Initialization
    
    init(color: Color? = nil,
         borderColor: Color? = nil,
         borderWidth: Double? = nil,
         cornerRadius: Double? = nil) {
        self.color = color
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }
    
    init(text: String, textStyle: TextStyle) {
        self.text = text
        self.textStyle = textStyle
    }
    
    init(garmentType: GarmentType,
         color: Color? = nil,
         pattern: Pattern? = nil) {
        self.garmentType = garmentType
        self.garmentColor = color
        self.garmentPattern = pattern
    }
    
    init(pattern: Pattern) {
        self.pattern = pattern
    }
    
    init(shapeType: ShapeType,
         color: Color? = nil,
         borderColor: Color? = nil,
         borderWidth: Double? = nil,
         cornerRadius: Double? = nil) {
        self.shapeType = shapeType
        self.color = color
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Coding
    
    private enum CodingKeys: String, CodingKey {
        case colorHex, borderColorHex, borderWidth, cornerRadius
        case text, textStyle
        case garmentType, garmentColorHex, garmentPattern
        case pattern
        case shapeType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) {
            color = Color(hex: colorHex)
        }
        if let borderColorHex = try container.decodeIfPresent(String.self, forKey: .borderColorHex) {
            borderColor = Color(hex: borderColorHex)
        }
        borderWidth = try container.decodeIfPresent(Double.self, forKey: .borderWidth)
        cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius)
        
        text = try container.decodeIfPresent(String.self, forKey: .text)
        textStyle = try container.decodeIfPresent(TextStyle.self, forKey: .textStyle)
        
        garmentType = try container.decodeIfPresent(GarmentType.self, forKey: .garmentType)
        if let garmentColorHex = try container.decodeIfPresent(String.self, forKey: .garmentColorHex) {
            garmentColor = Color(hex: garmentColorHex)
        }
        garmentPattern = try container.decodeIfPresent(Pattern.self, forKey: .garmentPattern)
        
        pattern = try container.decodeIfPresent(Pattern.self, forKey: .pattern)
        shapeType = try container.decodeIfPresent(ShapeType.self, forKey: .shapeType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(color?.toHex(), forKey: .colorHex)
        try container.encodeIfPresent(borderColor?.toHex(), forKey: .borderColorHex)
        try container.encodeIfPresent(borderWidth, forKey: .borderWidth)
        try container.encodeIfPresent(cornerRadius, forKey: .cornerRadius)
        
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(textStyle, forKey: .textStyle)
        
        try container.encodeIfPresent(garmentType, forKey: .garmentType)
        try container.encodeIfPresent(garmentColor?.toHex(), forKey: .garmentColorHex)
        try container.encodeIfPresent(garmentPattern, forKey: .garmentPattern)
        
        try container.encodeIfPresent(pattern, forKey: .pattern)
        try container.encodeIfPresent(shapeType, forKey: .shapeType)
    }
}

// MARK: - Point Coding

extension CGPoint: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

// MARK: - Preview

#if DEBUG
extension DesignItem {
    static var preview: DesignItem {
        DesignItem(
            type: .garment,
            position: CGPoint(x: 200, y: 200),
            size: CGSize(width: 200, height: 200),
            properties: ElementProperties(
                garmentType: .shirt,
                color: .blue
            )
        )
    }
    
    static var previewText: DesignItem {
        DesignItem(
            type: .text,
            position: CGPoint(x: 300, y: 300),
            size: CGSize(width: 200, height: 100),
            properties: ElementProperties(
                text: "Sample Text",
                textStyle: TextStyle(
                    font: .system(.title),
                    color: .black,
                    alignment: .center
                )
            )
        )
    }
} 