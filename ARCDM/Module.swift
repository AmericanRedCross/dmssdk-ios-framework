//
//  Module.swift
//  ARCDM
//
//  Created by Matthew Cheetham on 15/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

/// A object representation of a module.
/// This object recurses and can be displayed in the following structure
/// Module -> Module Step -> Step sub step -> Tools
public struct Module {
    
    /// The unique identifier of the module object
    public var identifier: Int?
    
    /// The position at which this module should be displayed when presented in a list
    public var order: Int = 0
    
    /// The assosciated metadata. This contains additional information about the module object.
    public var metadata: [AnyHashable: Any]?
    
    /// The title of the module
    public var moduleTitle: String?
    
    /// The raw markdown content of the module
    public var content: String?
    
    /// An array of module objects which are objects to display beneath this module when it is viewed expanded
    public var directories: [Module]?
    
    /// An array of file descriptors that are assosciated with this module
    public var attachments: [FileDescriptor]?
    
    /// If the module is marked as being a pert of the "Critical Path", this is true.
    public var critical: Bool = false
    
    init(with dictionary: [AnyHashable: Any]) {
        
        identifier = dictionary["id"] as? Int
        
        if let _order = dictionary["order"] as? Int {
            order = _order
        }
        
        metadata = dictionary["metadata"] as? [AnyHashable: Any]
        
        moduleTitle = dictionary["title"] as? String
        content = dictionary["content"] as? String
        
        if let _directories = dictionary["directories"] as? [[AnyHashable: Any]] {
            directories = _directories.flatMap({ Module(with: $0)})
        }
        
        if let _fileDescriptors = dictionary["attachments"] as? [[AnyHashable: Any]] {
            attachments = _fileDescriptors.flatMap({ FileDescriptor(with: $0)})
        }
        
        if let _critical = dictionary["critical"] as? Bool {
            critical = _critical
        }
    }
}
