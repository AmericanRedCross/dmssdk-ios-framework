//
//  ModuleManager.swift
//  ARCDM
//
//  Created by Matthew Cheetham on 16/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// A manager that loads the module data and provides utilities for loading data surrounding modules
public class DirectoryManager {
    
    /// An array of top level directories loaded using one of the `DirectoryManager` initialisers
    public var directories: [Directory]?
    
    /// Initialises the manager with an optional array of directories. If you wish to initialise using the `structure.json` from the parent app's bundle, please call the `init()` method
    ///
    /// - Parameter dataSource: An array of Directory objects that have been loaded from elsewhere
    public init(dataSource: [Directory]?) {
        directories = dataSource
    }
        
    /// Initialises the `DirectoryManager` using `structure.json` from the parent app's bundle if available.
    public convenience init() {
        
        if let _filePath = ContentManager().fileUrl(forResource: "structure", withExtension: "json", inDirectory: nil) {
            
            if let jsonFileData = NSData(contentsOfFile: _filePath.path) {
                
                let jsonObjects = try? JSONSerialization.jsonObject(with: jsonFileData as Data, options: [])
                
                if let _jsonObjects = jsonObjects as? [[AnyHashable: Any]] {
                    
                    let directories = _jsonObjects.flatMap({ Directory(with: $0)})
                    self.init(dataSource: directories)
                    return
                }
            }
        }
        self.init(dataSource: nil)
    }
    
    /// Initialises the `DirectoryManager` with a `String` that can be parsed into an array of `Directory` objects
    ///
    /// - Parameter dataSource: The `String` that can be parsed into `Directory` objects
    public convenience init(dataSource: String) {
        self.init(dataSource: dataSource)
    }
    
    /// Initialises the `DirectoryManager` with a JSON Object that can be parsed into an array of `Directory` objects
    ///
    /// - Parameter dataSource: A compatible JSON object
    public convenience init(dataSource: Any) {
        
        guard JSONSerialization.isValidJSONObject(dataSource) else {
            self.init(dataSource: nil)
            return
        }
        
        if let _jsonObjects = dataSource as? [[AnyHashable: Any]] {
            
            let directories = _jsonObjects.flatMap({ Directory(with: $0)})
            self.init(dataSource: directories)
            return
        }
        self.init()
    }
    
    /// Searches for a directory with a given identifier. This method will start with the given array and recurse through each items `directory` array until all paths are exhausted.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the `Directory` to search for
    ///   - directories: The array of directories to search through recursively
    /// - Returns: The `Directory` object if it was found, nil otherwise.
    public class func directory(for identifier: Int, in directories: [Directory]) -> Directory? {
        
        for localDirectory in directories {
            
            let directoryID = localDirectory.identifier
            
            if directoryID == identifier {
                return localDirectory
            }
            
            if let directories = localDirectory.directories {
                
                if let subDirectory = directory(for: identifier, in: directories) {
                    return subDirectory
                }
            }
        }
        return nil
    }
}
