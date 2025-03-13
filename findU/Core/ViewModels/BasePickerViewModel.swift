import SwiftUI
import Combine

protocol RecentlyUsable {
    associatedtype Item: Equatable
    var recentItems: [Item] { get set }
    func addRecentItem(_ item: Item)
    func loadRecentItems() async throws
    func saveRecentItems() async throws
}

protocol Favoritable {
    associatedtype Item: Identifiable
    var favoriteItems: Set<Item.ID> { get set }
    func toggleFavorite(_ item: Item)
    func isFavorite(_ item: Item) -> Bool
    func loadFavorites() async throws
    func saveFavorites() async throws
}

class BasePickerViewModel<T>: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    var subscriptions = Set<AnyCancellable>()
    let designService: DesignService
    
    init(designService: DesignService = DesignService()) {
        self.designService = designService
    }
    
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isLoading = false
        }
    }
    
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
}

class BaseItemPickerViewModel<T: Identifiable & Equatable>: BasePickerViewModel<T>, RecentlyUsable, Favoritable {
    typealias Item = T
    
    @Published var recentItems: [T] = []
    @Published var favoriteItems: Set<T.ID> = []
    
    override init(designService: DesignService = DesignService()) {
        super.init(designService: designService)
        Task {
            try? await loadRecentItems()
            try? await loadFavorites()
        }
    }
    
    func addRecentItem(_ item: T) {
        if !recentItems.contains(item) {
            recentItems.insert(item, at: 0)
            if recentItems.count > 10 {
                recentItems.removeLast()
            }
            Task {
                try? await saveRecentItems()
            }
        }
    }
    
    func loadRecentItems() async throws {
        // Override in subclass
        fatalError("loadRecentItems() must be overridden")
    }
    
    func saveRecentItems() async throws {
        // Override in subclass
        fatalError("saveRecentItems() must be overridden")
    }
    
    func toggleFavorite(_ item: T) {
        if favoriteItems.contains(item.id) {
            favoriteItems.remove(item.id)
        } else {
            favoriteItems.insert(item.id)
        }
        Task {
            try? await saveFavorites()
        }
    }
    
    func isFavorite(_ item: T) -> Bool {
        favoriteItems.contains(item.id)
    }
    
    func loadFavorites() async throws {
        // Override in subclass
        fatalError("loadFavorites() must be overridden")
    }
    
    func saveFavorites() async throws {
        // Override in subclass
        fatalError("saveFavorites() must be overridden")
    }
}

class BaseBackgroundPickerViewModel: BasePickerViewModel<CanvasBackground>, RecentlyUsable {
    typealias Item = CanvasBackground
    
    @Published var recentItems: [CanvasBackground] = []
    @Published var selectedColor: Color = .white
    @Published var gradientStartColor: Color = .blue
    @Published var gradientEndColor: Color = .purple
    @Published var gradientAngle: Double = 45
    
    override init(designService: DesignService = DesignService()) {
        super.init(designService: designService)
        Task {
            try? await loadRecentItems()
        }
    }
    
    var backgroundTemplates: [CanvasBackground] {
        [
            .solid(color: .white),
            .solid(color: .black),
            .gradient(colors: [.blue, .purple], angle: 45),
            .gradient(colors: [.orange, .red], angle: 45),
            .gradient(colors: [.green, .blue], angle: 45)
        ]
    }
    
    func addRecentItem(_ item: CanvasBackground) {
        if !recentItems.contains(item) {
            recentItems.insert(item, at: 0)
            if recentItems.count > 10 {
                recentItems.removeLast()
            }
            Task {
                try? await saveRecentItems()
            }
        }
    }
    
    func loadRecentItems() async throws {
        let recent = try await designService.loadRecentBackgrounds()
        await MainActor.run {
            // Convert backgrounds to CanvasBackground type
            self.recentItems = recent.colors.map { .solid(color: $0) } +
                             recent.gradients.map { .gradient(colors: $0.colors, angle: $0.angle) }
        }
    }
    
    func saveRecentItems() async throws {
        var colors: [Color] = []
        var gradients: [Gradient] = []
        
        for item in recentItems {
            switch item {
            case .solid(let color):
                colors.append(color)
            case .gradient(let colors, let angle):
                gradients.append(Gradient(colors: colors, angle: angle))
            default:
                break
            }
        }
        
        try await designService.saveRecentBackgrounds(
            colors: colors,
            gradients: gradients,
            images: []
        )
    }
} 