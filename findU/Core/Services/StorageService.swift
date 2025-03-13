import Foundation
import CoreData
import Combine

enum StorageError: Error {
    case saveError
    case fetchError
    case deleteError
    case invalidData
}

class StorageService {
    static let shared = StorageService()
    
    // MARK: - Core Data stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "findU")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - UserDefaults wrapper
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Core Data Operations
    func save() throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw StorageError.saveError
            }
        }
    }
    
    func fetch<T: NSManagedObject>(_ type: T.Type,
                                  predicate: NSPredicate? = nil,
                                  sortDescriptors: [NSSortDescriptor]? = nil) throws -> [T] {
        let request = T.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            let result = try context.fetch(request)
            return result as? [T] ?? []
        } catch {
            throw StorageError.fetchError
        }
    }
    
    func delete(_ object: NSManagedObject) throws {
        context.delete(object)
        try save()
    }
    
    func deleteAll<T: NSManagedObject>(_ type: T.Type) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
            try save()
        } catch {
            throw StorageError.deleteError
        }
    }
    
    // MARK: - UserDefaults Operations
    func setValue(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func getValue(forKey key: String) -> Any? {
        return defaults.object(forKey: key)
    }
    
    func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    // MARK: - Codable Object Storage
    func saveCodableObject<T: Codable>(_ object: T, forKey key: String) throws {
        do {
            let data = try JSONEncoder().encode(object)
            defaults.set(data, forKey: key)
        } catch {
            throw StorageError.saveError
        }
    }
    
    func loadCodableObject<T: Codable>(forKey key: String) throws -> T {
        guard let data = defaults.data(forKey: key) else {
            throw StorageError.invalidData
        }
        
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            throw StorageError.fetchError
        }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        guard let cacheDirectory = urls.first else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory,
                                                                     includingPropertiesForKeys: nil,
                                                                     options: [])
            for fileUrl in contents {
                try FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
    
    // MARK: - Memory Warning Handler
    func handleMemoryWarning() {
        context.refreshAllObjects()
    }
} 