import Foundation
import FirebaseFirestoreSwift

struct DesignTemplate: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let category: TemplateCategory
    let previewUrl: String
    let canvas: DesignCanvas
    let tags: Set<String>
    let isCustom: Bool
    let dateCreated: Date
    let creatorId: String?
    let metadata: [String: String]?
    
    enum TemplateCategory: String, Codable, CaseIterable {
        case basic
        case casual
        case formal
        case sport
        case custom
        case other
    }
    
    init(id: String? = nil,
         name: String,
         category: TemplateCategory,
         previewUrl: String,
         canvas: DesignCanvas,
         tags: Set<String> = [],
         isCustom: Bool = false,
         dateCreated: Date = Date(),
         creatorId: String? = nil,
         metadata: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.previewUrl = previewUrl
        self.canvas = canvas
        self.tags = tags
        self.isCustom = isCustom
        self.dateCreated = dateCreated
        self.creatorId = creatorId
        self.metadata = metadata
    }
}

struct DesignVersion: Identifiable, Codable {
    @DocumentID var id: String?
    let designId: String
    let version: Int
    let canvas: DesignCanvas
    let timestamp: Date
    let authorId: String
    let comment: String?
    let metadata: [String: String]?
    
    init(id: String? = nil,
         designId: String,
         version: Int,
         canvas: DesignCanvas,
         timestamp: Date = Date(),
         authorId: String,
         comment: String? = nil,
         metadata: [String: String]? = nil) {
        self.id = id
        self.designId = designId
        self.version = version
        self.canvas = canvas
        self.timestamp = timestamp
        self.authorId = authorId
        self.comment = comment
        self.metadata = metadata
    }
}

// MARK: - Preview

#if DEBUG
extension DesignTemplate {
    static var preview: DesignTemplate {
        DesignTemplate(
            name: "Basic Outfit",
            category: .basic,
            previewUrl: "template_preview_1",
            canvas: DesignCanvas.preview,
            tags: ["casual", "simple", "starter"],
            creatorId: "system"
        )
    }
    
    static var previewArray: [DesignTemplate] {
        [
            preview,
            DesignTemplate(
                name: "Formal Suit",
                category: .formal,
                previewUrl: "template_preview_2",
                canvas: DesignCanvas.preview,
                tags: ["formal", "business", "professional"],
                creatorId: "system"
            ),
            DesignTemplate(
                name: "Sport Outfit",
                category: .sport,
                previewUrl: "template_preview_3",
                canvas: DesignCanvas.preview,
                tags: ["sport", "athletic", "casual"],
                creatorId: "system"
            )
        ]
    }
}

extension DesignVersion {
    static var preview: DesignVersion {
        DesignVersion(
            designId: "design123",
            version: 1,
            canvas: DesignCanvas.preview,
            authorId: "user123",
            comment: "Initial version"
        )
    }
    
    static var previewArray: [DesignVersion] {
        [
            preview,
            DesignVersion(
                designId: "design123",
                version: 2,
                canvas: DesignCanvas.preview,
                authorId: "user123",
                comment: "Updated colors"
            ),
            DesignVersion(
                designId: "design123",
                version: 3,
                canvas: DesignCanvas.preview,
                authorId: "user123",
                comment: "Added new items"
            )
        ]
    }
}
#endif 