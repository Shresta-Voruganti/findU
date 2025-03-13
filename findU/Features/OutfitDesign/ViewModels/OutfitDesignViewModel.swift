import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import Combine

class OutfitDesignViewModel: ObservableObject, CanvasViewModel, Exportable {
    @Published var items: [DesignItem] = []
    @Published var selectedItem: DesignItem?
    @Published var background: CanvasBackground = .solid(color: .white)
    @Published var isLoading = false
    @Published var error: Error?
    @Published var templates: [DesignTemplate] = []
    @Published var versions: [DesignVersion] = []
    @Published var selectedTool: DesignTool = .select
    @Published var showError = false
    @Published var errorMessage: String?
    
    let canvasSize: CGSize = CGSize(width: 1024, height: 1024)
    let historyManager = HistoryManager<DesignItem>()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Tool Properties
    
    @Published var selectedColor: Color = .black
    @Published var selectedFontSize: CGFloat = 16
    @Published var selectedFont: String = "Helvetica"
    @Published var selectedGarmentType: ElementProperties.GarmentType = .shirt
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var canvas: DesignCanvas
    
    // MARK: - Initialization
    
    init(canvas: DesignCanvas? = nil) {
        self.canvas = canvas ?? DesignCanvas(
            id: UUID().uuidString,
            name: "Untitled Design",
            size: CGSize(width: 1024, height: 1024),
            items: [],
            background: .solid(color: .white),
            createdAt: Date(),
            updatedAt: Date(),
            version: 1
        )
        setupSubscriptions()
        loadTemplates()
    }
    
    private func setupSubscriptions() {
        $items
            .dropFirst()
            .sink { [weak self] items in
                self?.canvas.items = items
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Canvas Operations
    
    func moveItem(_ id: UUID, to position: CGPoint) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].isLocked else { return }
        
        let oldPosition = items[index].position
        historyManager.addAction(CanvasAction(
            execute: {
                self.items[index].position = position
            },
            undo: {
                self.items[index].position = oldPosition
            },
            description: "Move item"
        ))
    }
    
    func resizeItem(_ id: UUID, to size: CGSize) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].isLocked else { return }
        
        let oldSize = items[index].size
        historyManager.addAction(CanvasAction(
            execute: {
                self.items[index].size = size
            },
            undo: {
                self.items[index].size = oldSize
            },
            description: "Resize item"
        ))
    }
    
    func rotateItem(_ id: UUID, by angle: Double) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].isLocked else { return }
        
        let oldRotation = items[index].rotation
        historyManager.addAction(CanvasAction(
            execute: {
                self.items[index].rotation = angle
            },
            undo: {
                self.items[index].rotation = oldRotation
            },
            description: "Rotate item"
        ))
    }
    
    func setItemOpacity(_ id: UUID, to opacity: Double) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].isLocked else { return }
        
        let oldOpacity = items[index].opacity
        historyManager.addAction(CanvasAction(
            execute: {
                self.items[index].opacity = opacity
            },
            undo: {
                self.items[index].opacity = oldOpacity
            },
            description: "Change opacity"
        ))
    }
    
    func setItemZIndex(_ id: UUID, to zIndex: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].isLocked else { return }
        
        let oldZIndex = items[index].zIndex
        historyManager.addAction(CanvasAction(
            execute: {
                self.items[index].zIndex = zIndex
            },
            undo: {
                self.items[index].zIndex = oldZIndex
            },
            description: "Change layer order"
        ))
    }
    
    func toggleItemLock(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        let oldLocked = items[index].isLocked
        historyManager.addAction(CanvasAction(
            execute: {
                self.items[index].isLocked.toggle()
            },
            undo: {
                self.items[index].isLocked = oldLocked
            },
            description: "Toggle lock"
        ))
    }
    
    func deleteItem(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].isLocked else { return }
        
        let item = items[index]
        historyManager.addAction(CanvasAction(
            execute: {
                self.items.remove(at: index)
            },
            undo: {
                self.items.insert(item, at: index)
            },
            description: "Delete item"
        ))
    }
    
    // MARK: - Design Operations
    
    func addText(_ text: String, style: TextStyle) {
        let textItem = DesignItem(
            id: UUID(),
            type: .text,
            position: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
            size: CGSize(width: 200, height: 100),
            rotation: 0,
            opacity: 1,
            zIndex: items.count,
            isLocked: false,
            properties: .init(text: text, textStyle: style)
        )
        
        historyManager.addAction(CanvasAction(
            execute: {
                self.items.append(textItem)
            },
            undo: {
                self.items.removeLast()
            },
            description: "Add text"
        ))
    }
    
    func addGarment(type: ElementProperties.GarmentType) {
        let garment = DesignItem(
            id: UUID(),
            type: .garment,
            position: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
            size: CGSize(width: 200, height: 200),
            rotation: 0,
            opacity: 1,
            zIndex: items.count,
            isLocked: false,
            properties: .init(garmentType: type)
        )
        
        historyManager.addAction(CanvasAction(
            execute: {
                self.items.append(garment)
            },
            undo: {
                self.items.removeLast()
            },
            description: "Add garment"
        ))
    }
    
    func addPattern(_ pattern: Pattern) {
        let patternItem = DesignItem(
            id: UUID(),
            type: .pattern,
            position: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
            size: CGSize(width: 200, height: 200),
            rotation: 0,
            opacity: 1,
            zIndex: items.count,
            isLocked: false,
            properties: .init(pattern: pattern)
        )
        
        historyManager.addAction(CanvasAction(
            execute: {
                self.items.append(patternItem)
            },
            undo: {
                self.items.removeLast()
            },
            description: "Add pattern"
        ))
    }
    
    // MARK: - Firebase Operations
    
    @MainActor
    func saveDesign() async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        // Update canvas
        canvas.updatedAt = Date()
        canvas.version += 1
        
        // Save to Firestore
        try await db.collection("designs").document(canvas.id).setData(from: canvas)
        
        // Create version history
        let version = DesignVersion(
            id: UUID().uuidString,
            designId: canvas.id,
            version: canvas.version,
            canvas: canvas,
            timestamp: Date(),
            authorId: AuthManager.shared.currentUserId
        )
        
        try await db.collection("designVersions").document(version.id).setData(from: version)
        versions.append(version)
        
        return canvas.id
    }
    
    @MainActor
    func loadDesign(_ id: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let document = try await db.collection("designs").document(id).getDocument()
        canvas = try document.data(as: DesignCanvas.self)
        items = canvas.items
        background = canvas.background
        
        await loadVersionHistory()
    }
    
    // MARK: - Template Management
    
    func loadTemplates(category: DesignTemplate.TemplateCategory? = nil) {
        Task {
            do {
                var query: Query = db.collection("designTemplates")
                if let category = category {
                    query = query.whereField("category", isEqualTo: category.rawValue)
                }
                
                let snapshot = try await query.getDocuments()
                await MainActor.run {
                    self.templates = try? snapshot.documents.compactMap { try $0.data(as: DesignTemplate.self) }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    @MainActor
    func saveAsTemplate() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Generate preview image
        guard let previewImage = render(size: CGSize(width: 512, height: 512)) else {
            throw DesignError.previewGenerationFailed
        }
        
        // Upload preview image
        let imageData = previewImage.jpegData(compressionQuality: 0.8)
        let imageRef = storage.reference().child("templatePreviews/\(UUID().uuidString).jpg")
        _ = try await imageRef.putDataAsync(imageData!)
        let previewUrl = try await imageRef.downloadURL().absoluteString
        
        // Create template
        let template = DesignTemplate(
            id: UUID().uuidString,
            name: canvas.name,
            category: .custom,
            previewUrl: previewUrl,
            canvas: canvas,
            tags: [],
            isCustom: true
        )
        
        try await db.collection("designTemplates").document(template.id).setData(from: template)
        templates.append(template)
    }
    
    // MARK: - Version History
    
    func loadVersionHistory() async {
        guard let designId = canvas.id else { return }
        
        do {
            let snapshot = try await db.collection("designVersions")
                .whereField("designId", isEqualTo: designId)
                .order(by: "version", descending: true)
                .getDocuments()
            
            await MainActor.run {
                self.versions = try? snapshot.documents.compactMap { try $0.data(as: DesignVersion.self) }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func revertToVersion(_ version: DesignVersion) {
        historyManager.addAction(CanvasAction(
            execute: {
                self.canvas = version.canvas
                self.items = version.canvas.items
                self.background = version.canvas.background
            },
            undo: {
                // Store current state before reverting
                let currentCanvas = self.canvas
                self.canvas = currentCanvas
                self.items = currentCanvas.items
                self.background = currentCanvas.background
            },
            description: "Revert to version \(version.version)"
        ))
    }
    
    // MARK: - Export
    
    func render(size: CGSize) -> UIView {
        let containerView = UIView(frame: CGRect(origin: .zero, size: size))
        containerView.backgroundColor = UIColor(background.color)
        
        // Render items
        for item in items.sorted(by: { $0.zIndex < $1.zIndex }) {
            let itemView = renderItem(item)
            containerView.addSubview(itemView)
        }
        
        return containerView
    }
    
    private func renderItem(_ item: DesignItem) -> UIView {
        let containerView = UIView(frame: CGRect(origin: item.position, size: item.size))
        containerView.backgroundColor = .clear
        
        // Apply common transformations
        containerView.transform = CGAffineTransform(rotationAngle: CGFloat(item.rotation))
        containerView.alpha = CGFloat(item.opacity)
        
        // Create content view based on item type
        let contentView: UIView
        switch item.type {
        case .garment:
            contentView = renderGarment(item)
        case .pattern:
            contentView = renderPattern(item)
        case .text:
            contentView = renderText(item)
        case .shape:
            contentView = renderShape(item)
        }
        
        contentView.frame = containerView.bounds
        containerView.addSubview(contentView)
        
        return containerView
    }
    
    private func renderGarment(_ item: DesignItem) -> UIView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(item.properties.garmentColor ?? .clear)
        
        // Load garment image based on type
        if let garmentType = item.properties.garmentType {
            imageView.image = UIImage(named: "garment_\(garmentType.rawValue)")
        }
        
        // Apply pattern if exists
        if let pattern = item.properties.garmentPattern {
            // Apply pattern overlay
            let patternView = renderPattern(DesignItem(
                type: .pattern,
                position: .zero,
                size: item.size,
                properties: ElementProperties(pattern: pattern)
            ))
            patternView.frame = imageView.bounds
            imageView.addSubview(patternView)
            patternView.alpha = 0.8 // Adjust pattern opacity
        }
        
        return imageView
    }
    
    private func renderPattern(_ item: DesignItem) -> UIView {
        guard let pattern = item.properties.pattern else {
            return UIView()
        }
        
        let patternView = UIView(frame: .zero)
        
        // Create pattern based on type
        switch pattern.type {
        case .dots:
            renderDotPattern(on: patternView, with: pattern)
        case .stripes:
            renderStripePattern(on: patternView, with: pattern)
        case .checks:
            renderCheckPattern(on: patternView, with: pattern)
        case .herringbone:
            renderHerringbonePattern(on: patternView, with: pattern)
        case .floral:
            // Use image-based pattern
            if let image = UIImage(named: "pattern_floral") {
                patternView.backgroundColor = UIColor(patternImage: image)
            }
        case .geometric:
            renderGeometricPattern(on: patternView, with: pattern)
        case .abstract, .custom:
            // Use custom pattern image if available
            if let previewURL = pattern.previewURL,
               let url = URL(string: previewURL),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                patternView.backgroundColor = UIColor(patternImage: image)
            }
        }
        
        return patternView
    }
    
    private func renderText(_ item: DesignItem) -> UIView {
        guard let text = item.properties.text,
              let style = item.properties.textStyle else {
            return UIView()
        }
        
        let label = UILabel(frame: .zero)
        label.text = text
        label.textColor = UIColor(style.color)
        label.textAlignment = NSTextAlignment(style.alignment)
        
        // Apply font style
        var font = UIFont(descriptor: style.font.asFontDescriptor(), size: 0)
        if style.isBold {
            font = font.bold()
        }
        if style.isItalic {
            font = font.italic()
        }
        label.font = font
        
        // Apply text decorations
        if style.isUnderlined {
            label.underline()
        }
        if style.isStrikethrough {
            label.strikethrough()
        }
        
        // Apply spacing
        if let lineSpacing = style.lineSpacing {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            label.attributedText = NSAttributedString(
                string: text,
                attributes: [.paragraphStyle: paragraphStyle]
            )
        }
        
        if let letterSpacing = style.letterSpacing {
            label.attributedText = NSAttributedString(
                string: text,
                attributes: [.kern: letterSpacing]
            )
        }
        
        return label
    }
    
    private func renderShape(_ item: DesignItem) -> UIView {
        guard let shapeType = item.properties.shapeType else {
            return UIView()
        }
        
        let shapeView = UIView(frame: .zero)
        shapeView.backgroundColor = UIColor(item.properties.color ?? .clear)
        
        if let borderColor = item.properties.borderColor,
           let borderWidth = item.properties.borderWidth {
            shapeView.layer.borderColor = UIColor(borderColor).cgColor
            shapeView.layer.borderWidth = borderWidth
        }
        
        if let cornerRadius = item.properties.cornerRadius {
            shapeView.layer.cornerRadius = cornerRadius
        }
        
        switch shapeType {
        case .rectangle:
            // Already handled by the view's frame
            break
            
        case .circle:
            shapeView.layer.cornerRadius = min(item.size.width, item.size.height) / 2
            
        case .triangle:
            let trianglePath = UIBezierPath()
            trianglePath.move(to: CGPoint(x: item.size.width / 2, y: 0))
            trianglePath.addLine(to: CGPoint(x: item.size.width, y: item.size.height))
            trianglePath.addLine(to: CGPoint(x: 0, y: item.size.height))
            trianglePath.close()
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = trianglePath.cgPath
            shapeLayer.fillColor = UIColor(item.properties.color ?? .clear).cgColor
            shapeView.layer.mask = shapeLayer
            
        case .star:
            let starPath = createStarPath(in: CGRect(origin: .zero, size: item.size))
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = starPath.cgPath
            shapeLayer.fillColor = UIColor(item.properties.color ?? .clear).cgColor
            shapeView.layer.mask = shapeLayer
            
        case .heart:
            let heartPath = createHeartPath(in: CGRect(origin: .zero, size: item.size))
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = heartPath.cgPath
            shapeLayer.fillColor = UIColor(item.properties.color ?? .clear).cgColor
            shapeView.layer.mask = shapeLayer
            
        case .custom:
            // Handle custom shapes if needed
            break
        }
        
        return shapeView
    }
    
    // MARK: - Pattern Rendering Helpers
    
    private func renderDotPattern(on view: UIView, with pattern: Pattern) {
        let size = view.bounds.size
        let scale = pattern.scale
        let colors = pattern.colors
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let dotSize = CGSize(width: scale, height: scale)
        let spacing = scale * 2
        
        for row in stride(from: 0, to: size.height + spacing, by: spacing) {
            for col in stride(from: 0, to: size.width + spacing, by: spacing) {
                let colorIndex = ((Int(row / spacing) + Int(col / spacing)) % colors.count)
                context.setFillColor(UIColor(colors[colorIndex]).cgColor)
                
                let rect = CGRect(
                    x: col - dotSize.width/2,
                    y: row - dotSize.height/2,
                    width: dotSize.width,
                    height: dotSize.height
                )
                context.fillEllipse(in: rect)
            }
        }
        
        if let patternImage = UIGraphicsGetImageFromCurrentImageContext() {
            view.backgroundColor = UIColor(patternImage: patternImage)
        }
    }
    
    private func renderStripePattern(on view: UIView, with pattern: Pattern) {
        let size = view.bounds.size
        let scale = pattern.scale
        let colors = pattern.colors
        let rotation = pattern.rotation
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Apply rotation
        context.translateBy(x: size.width/2, y: size.height/2)
        context.rotate(by: CGFloat(rotation) * .pi / 180)
        context.translateBy(x: -size.width/2, y: -size.height/2)
        
        let stripeWidth = scale
        var currentX: CGFloat = 0
        
        while currentX < size.width + stripeWidth {
            let colorIndex = Int(currentX / stripeWidth) % colors.count
            context.setFillColor(UIColor(colors[colorIndex]).cgColor)
            
            let rect = CGRect(x: currentX, y: -size.height, width: stripeWidth, height: size.height * 3)
            context.fill(rect)
            
            currentX += stripeWidth
        }
        
        if let patternImage = UIGraphicsGetImageFromCurrentImageContext() {
            view.backgroundColor = UIColor(patternImage: patternImage)
        }
    }
    
    private func renderCheckPattern(on view: UIView, with pattern: Pattern) {
        let size = view.bounds.size
        let scale = pattern.scale
        let colors = pattern.colors
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let checkSize = CGSize(width: scale, height: scale)
        
        for row in stride(from: 0, to: size.height + scale, by: scale) {
            for col in stride(from: 0, to: size.width + scale, by: scale) {
                let colorIndex = ((Int(row / scale) + Int(col / scale)) % colors.count)
                context.setFillColor(UIColor(colors[colorIndex]).cgColor)
                
                let rect = CGRect(
                    x: col,
                    y: row,
                    width: checkSize.width,
                    height: checkSize.height
                )
                context.fill(rect)
            }
        }
        
        if let patternImage = UIGraphicsGetImageFromCurrentImageContext() {
            view.backgroundColor = UIColor(patternImage: patternImage)
        }
    }
    
    private func renderHerringbonePattern(on view: UIView, with pattern: Pattern) {
        let size = view.bounds.size
        let scale = pattern.scale
        let colors = pattern.colors
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let lineWidth = scale * 0.2
        let spacing = scale
        let angle: CGFloat = .pi / 4
        
        context.setLineWidth(lineWidth)
        
        for row in stride(from: -size.height, to: size.height * 2, by: spacing) {
            for colorIndex in 0..<colors.count {
                context.setStrokeColor(UIColor(colors[colorIndex]).cgColor)
                
                let yOffset = CGFloat(colorIndex) * spacing / CGFloat(colors.count)
                
                // Draw forward slash
                let path1 = UIBezierPath()
                path1.move(to: CGPoint(x: -size.width, y: row + yOffset))
                path1.addLine(to: CGPoint(x: size.width * 2, y: row + size.width * 3 + yOffset))
                context.addPath(path1.cgPath)
                context.strokePath()
                
                // Draw back slash
                let path2 = UIBezierPath()
                path2.move(to: CGPoint(x: -size.width, y: row + size.width * 3 + yOffset))
                path2.addLine(to: CGPoint(x: size.width * 2, y: row + yOffset))
                context.addPath(path2.cgPath)
                context.strokePath()
            }
        }
        
        if let patternImage = UIGraphicsGetImageFromCurrentImageContext() {
            view.backgroundColor = UIColor(patternImage: patternImage)
        }
    }
    
    private func renderGeometricPattern(on view: UIView, with pattern: Pattern) {
        let size = view.bounds.size
        let scale = pattern.scale
        let colors = pattern.colors
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let tileSize = CGSize(width: scale, height: scale)
        
        for row in stride(from: 0, to: size.height + scale, by: scale) {
            for col in stride(from: 0, to: size.width + scale, by: scale) {
                let colorIndex = ((Int(row / scale) + Int(col / scale)) % colors.count)
                context.setFillColor(UIColor(colors[colorIndex]).cgColor)
                
                let rect = CGRect(origin: CGPoint(x: col, y: row), size: tileSize)
                let path = UIBezierPath()
                
                // Create hexagon shape
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let radius = min(rect.width, rect.height) / 2
                
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3
                    let point = CGPoint(
                        x: center.x + radius * cos(angle),
                        y: center.y + radius * sin(angle)
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                
                path.close()
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
        
        if let patternImage = UIGraphicsGetImageFromCurrentImageContext() {
            view.backgroundColor = UIColor(patternImage: patternImage)
        }
    }
    
    // MARK: - Shape Path Helpers
    
    private func createStarPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2
        let points = 5
        
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points)
            let pointRadius = i % 2 == 0 ? radius : radius * 0.4
            let x = center.x + pointRadius * cos(angle)
            let y = center.y + pointRadius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.close()
        return path
    }
    
    private func createHeartPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            controlPoint1: CGPoint(x: width / 2 - width / 4, y: height * 3 / 4),
            controlPoint2: CGPoint(x: 0, y: height / 2)
        )
        path.addArc(
            withCenter: CGPoint(x: width / 4, y: height / 4),
            radius: width / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addArc(
            withCenter: CGPoint(x: width * 3 / 4, y: height / 4),
            radius: width / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            controlPoint1: CGPoint(x: width, y: height / 2),
            controlPoint2: CGPoint(x: width / 2 + width / 4, y: height * 3 / 4)
        )
        path.close()
        
        return path
    }
    
    // MARK: - Enums
    
    enum DesignTool {
        case select, text, image, shape, garment, pattern, eraser
    }
    
    enum DesignError: LocalizedError {
        case previewGenerationFailed
        
        var errorDescription: String? {
            switch self {
            case .previewGenerationFailed:
                return "Failed to generate preview image"
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
extension OutfitDesignViewModel {
    static func preview() -> OutfitDesignViewModel {
        let viewModel = OutfitDesignViewModel()
        
        // Add sample items
        viewModel.items = [
            DesignItem(
                type: .garment,
                position: CGPoint(x: 200, y: 200),
                size: CGSize(width: 200, height: 200),
                properties: ElementProperties(
                    garmentType: .shirt,
                    color: .blue
                )
            ),
            DesignItem(
                type: .text,
                position: CGPoint(x: 300, y: 300),
                size: CGSize(width: 200, height: 100),
                properties: ElementProperties(
                    text: "Sample Text",
                    textStyle: TextStyle(
                        font: .system(.title),
                        color: .black,
                        alignment: .center,
                        isBold: true
                    )
                )
            ),
            DesignItem(
                type: .pattern,
                position: CGPoint(x: 400, y: 200),
                size: CGSize(width: 150, height: 150),
                properties: ElementProperties(
                    pattern: Pattern(
                        name: "Classic Dots",
                        type: .dots,
                        colors: [.white, .black],
                        category: .basic
                    )
                )
            ),
            DesignItem(
                type: .shape,
                position: CGPoint(x: 500, y: 300),
                size: CGSize(width: 100, height: 100),
                properties: ElementProperties(
                    shapeType: .heart,
                    color: .red,
                    borderColor: .black,
                    borderWidth: 2,
                    cornerRadius: 0
                )
            )
        ]
        
        // Add sample templates
        viewModel.templates = [
            DesignTemplate(
                name: "Basic Outfit",
                category: .basic,
                previewUrl: "template_preview_1",
                canvas: DesignCanvas.preview,
                tags: ["casual", "simple"]
            ),
            DesignTemplate(
                name: "Formal Suit",
                category: .formal,
                previewUrl: "template_preview_2",
                canvas: DesignCanvas.preview,
                tags: ["formal", "business"]
            )
        ]
        
        // Add sample versions
        viewModel.versions = [
            DesignVersion(
                designId: "design123",
                version: 1,
                canvas: DesignCanvas.preview,
                authorId: "user123",
                comment: "Initial version"
            ),
            DesignVersion(
                designId: "design123",
                version: 2,
                canvas: DesignCanvas.preview,
                authorId: "user123",
                comment: "Updated colors"
            )
        ]
        
        return viewModel
    }
} 