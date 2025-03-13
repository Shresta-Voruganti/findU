import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }
        
        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

#if DEBUG
extension Color {
    static let previewColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple,
        .pink, .gray, .black, .white
    ]
    
    static let previewHexColors: [String] = [
        "#FF0000", "#0000FF", "#00FF00", "#FFFF00",
        "#FFA500", "#800080", "#FFC0CB", "#808080",
        "#000000", "#FFFFFF"
    ]
} 