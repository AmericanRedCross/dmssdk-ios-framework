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

    var modules: [Module]?
    
    public init() {
        
        let filePath = Bundle.main.path(forResource: "structure", ofType: "json")
        
        if let _filePath = filePath, let jsonFileData = NSData(contentsOfFile: _filePath) {
            
            let jsonObjects = try? JSONSerialization.jsonObject(with: jsonFileData as Data, options: [])
            
            if let _jsonObjects = jsonObjects as? [[AnyHashable: Any]] {
                
                modules = _jsonObjects.flatMap({ Module(with: $0)})
                
            }
            
        }
        
    }
    
}
