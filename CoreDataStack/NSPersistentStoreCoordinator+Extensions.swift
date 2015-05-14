//
//  NSPersistentStoreCoordinator+Extensions.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 5/8/15.
//  Copyright (c) 2015 Big Nerd Ranch. All rights reserved.
//

import CoreData

public enum SetupResult {
    case Success(NSPersistentStoreCoordinator)
    case Failure(NSError)
}

public extension NSPersistentStoreCoordinator {

    public class func urlForSQLiteStore(#modelName: String?) -> NSURL {
        return defaultURL(modleName: modelName)
    }

    public class func setupSQLiteBackedCoordinator(managedObjectModel: NSManagedObjectModel, storeFileURL: NSURL?, completion: (SetupResult) -> Void) {
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(backgroundQueue) {
            var error: NSError?
            if let coordinator = NSPersistentStoreCoordinator.persistentStoreCoordinator(managedObjectModel: managedObjectModel, storeURL: storeFileURL, error:&error) {
                completion(SetupResult.Success(coordinator))
            } else if let error = error {
                completion(SetupResult.Failure(error))
            } else {
                fatalError("A coordinator or error should be returned")
            }
        }
    }

    private class func persistentStoreCoordinator(#managedObjectModel: NSManagedObjectModel, storeURL: NSURL?, error: NSErrorPointer) -> NSPersistentStoreCoordinator? {
        let url = storeURL ?? defaultURL(modleName: nil)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let storeOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true];

        // TODO: rcedwards NSSQLitePragmasOption: @"journal_mode = WAL" provides write ahead logging but may pose some issues:
        // http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/

        if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
            configuration: nil,
            URL: url,
            options: nil,
            error: error) {
                return coordinator
        } else if error.memory == nil {
            assertionFailure("Failed to add store and no error was returned")
        }

        return nil
    }

    private class func defaultURL(#modleName: String?) -> NSURL {
        let name = modleName ?? "coredatastore"
        return applicationDocumentsDirectory.URLByAppendingPathComponent("\(name).sqlite")
    }

    private static var applicationDocumentsDirectory: NSURL {
        get {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls[urls.count-1] as! NSURL
        }
    }
}

