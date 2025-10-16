//
//  Copyright 2024, Jamf
//

import CoreData
import Foundation

/// Main data manager for the SavableItems (Jamf Pro or Follder instances)
class DataManager: NSObject {
    #if !JAMF_SYNC_CLI
    @Published
    #endif
    var savableItems: [SavableItemData] = []

    /// Core Data container with the model name
    let container: NSPersistentContainer

    /// Default init method. Load the Core Data container
    override init() {
        print("TODO: REMOVE THIS!!! About to create NSPersistentContainer")
        container = NSPersistentContainer(name: "StoredSettings")

        // Conditionally set the store URL for CLI target
        #if JAMF_SYNC_CLI
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Jamf Sync", isDirectory: true)
            .appendingPathComponent("StoredSettings.sqlite")
        print("TODO: REMOVE THIS!!! storeURL=\(storeURL)")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        // Ensure the directory exists
        do {
            try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {
            LogManager.shared.logMessage(message: "Failed to create Application Support directory: \(error)", level: .error)
        }
        container.persistentStoreDescriptions = [storeDescription]
        #endif

        super.init()
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                LogManager.shared.logMessage(message: "Failed to load Core Data store: \(error), \(error.userInfo)", level: .error)
            } else {
                LogManager.shared.logMessage(message: "Successfully loaded Core Data store at \(storeDescription.url?.absoluteString ?? "unknown")", level: .info)
            }
        }
    }
}

#if !JAMF_SYNC_CLI
extension DataManager: ObservableObject {}
#endif
