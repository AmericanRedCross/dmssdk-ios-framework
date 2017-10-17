//
//  ModuleManager.swift
//  ARCDM
//
//  Created by Matthew Cheetham on 16/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import Foundation

/// A manager that loads the module data and provides utilities for loading data surrounding modules
public class ModuleManager {
    
    public var modules: [Directory]?
        
    public init() {
        
        if let _filePath = ContentController().fileUrl(forResource: "structure", withExtension: "json", inDirectory: nil) {
            
            print("<ModuleManager> Loading data from \(_filePath)")
            
            if let jsonFileData = NSData(contentsOfFile: _filePath.path) {
                
                let jsonObjects = try? JSONSerialization.jsonObject(with: jsonFileData as Data, options: [])
                
                if let _jsonObjects = jsonObjects as? [[AnyHashable: Any]] {
                    
                    modules = _jsonObjects.flatMap({ Directory(with: $0)})
                }
            }
        }
    }
    
    public func module(for identifier: Int, in modules: [Directory]) -> Directory? {
        
        for localModule in modules {
            
            let moduleId = localModule.identifier
            
            if moduleId == identifier {
                return localModule
            }
            
            if let directories = localModule.directories {
                
                if let directoryModule = module(for: identifier, in: directories) {
                    return directoryModule
                }
            }
        }
        
        return nil
    }
}
