import SwiftUI

struct TextStyle: Codable {
    var font: Font
    var color: Color
    var alignment: TextAlignment
    var lineSpacing: CGFloat?
    var letterSpacing: CGFloat?
    var isUnderlined: Bool
    var isStrikethrough: Bool
    var isBold: Bool
    var isItalic: Bool
    
    init(font: Font = .system(.body),
         color: Color = .black,
         alignment: TextAlignment = .leading,
         lineSpacing: CGFloat? = nil,
         letterSpacing: CGFloat? = nil,
         isUnderlined: Bool = false,
         isStrikethrough: Bool = false,
         isBold: Bool = false,
         isItalic: Bool = false) {
        self.font = font
        self.color = color
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.letterSpacing = letterSpacing
        self.isUnderlined = isUnderlined
        self.isStrikethrough = isStrikethrough
        self.isBold = isBold
        self.isItalic = isItalic
    }
    
    // MARK: - Coding
    
    private enum CodingKeys: String, CodingKey {
        case fontName, fontSize, colorHex, alignment
        case lineSpacing, letterSpacing
        case isUnderlined, isStrikethrough, isBold, isItalic
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let fontName = try container.decode(String.self, forKey: .fontName)
        let fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        font = .custom(fontName, size: fontSize)
        
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex) ?? .black
        
        alignment = try container.decode(TextAlignment.self, forKey: .alignment)
        lineSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .lineSpacing)
        letterSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .letterSpacing)
        isUnderlined = try container.decode(Bool.self, forKey: .isUnderlined)
        isStrikethrough = try container.decode(Bool.self, forKey: .isStrikethrough)
        isBold = try container.decode(Bool.self, forKey: .isBold)
        isItalic = try container.decode(Bool.self, forKey: .isItalic)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Extract font name and size from Font
        let fontDescriptor = font.asFontDescriptor()
        try container.encode(fontDescriptor.fontName, forKey: .fontName)
        try container.encode(fontDescriptor.pointSize, forKey: .fontSize)
        
        try container.encode(color.toHex() ?? "#000000", forKey: .colorHex)
        try container.encode(alignment, forKey: .alignment)
        try container.encodeIfPresent(lineSpacing, forKey: .lineSpacing)
        try container.encodeIfPresent(letterSpacing, forKey: .letterSpacing)
        try container.encode(isUnderlined, forKey: .isUnderlined)
        try container.encode(isStrikethrough, forKey: .isStrikethrough)
        try container.encode(isBold, forKey: .isBold)
        try container.encode(isItalic, forKey: .isItalic)
    }
}

// MARK: - Font Extensions

extension Font {
    func asFontDescriptor() -> UIFontDescriptor {
        // Convert SwiftUI Font to UIFont descriptor
        let uiFont: UIFont
        switch self {
        case .largeTitle:
            uiFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:
            uiFont = UIFont.preferredFont(forTextStyle: .title1)
        case .headline:
            uiFont = UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            uiFont = UIFont.preferredFont(forTextStyle: .subheadline)
        case .body:
            uiFont = UIFont.preferredFont(forTextStyle: .body)
        case .callout:
            uiFont = UIFont.preferredFont(forTextStyle: .callout)
        case .footnote:
            uiFont = UIFont.preferredFont(forTextStyle: .footnote)
        case .caption:
            uiFont = UIFont.preferredFont(forTextStyle: .caption1)
        default:
            uiFont = UIFont.preferredFont(forTextStyle: .body)
        }
        return uiFont.fontDescriptor
    }
}

// MARK: - Preview

#if DEBUG
extension TextStyle {
    static var preview: TextStyle {
        TextStyle(
            font: .system(.title),
            color: .black,
            alignment: .center,
            lineSpacing: 1.2,
            letterSpacing: 0.5,
            isUnderlined: false,
            isStrikethrough: false,
            isBold: true,
            isItalic: false
        )
    }
} 