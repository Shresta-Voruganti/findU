import SwiftUI

protocol CanvasItem: Identifiable {
    var id: UUID { get }
    var position: CGPoint { get set }
    var size: CGSize { get set }
    var rotation: Double { get set }
    var opacity: Double { get set }
    var zIndex: Int { get set }
    var isLocked: Bool { get set }
} 