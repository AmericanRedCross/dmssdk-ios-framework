//
//  Directory.swift
//  DMSSDK
//
//  Created by Matthew Cheetham on 15/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

/// A object representation of a directory.
/// This object recurses to an unknown number of levels through the `directories` variable
public struct Directory {
    
    /// The unique identifier of the directory object
    public var identifier: Int
    
    /// The identifier of the parent Directory if one exists
    public var parentIdentifier: Int?
    
    /// The position at which this directory should be displayed when presented in a list
    public var order: Int = 0
    
    /// The assosciated metadata. This contains additional information about the directory object.
    public var metadata: [AnyHashable: Any]?
    
    /// The title of the directory
    public var directoryTitle: String?
    
    /// The raw markdown content of the directory
    public var content: String?
    
    /// An array of directory objects which are objects to display beneath this directory when it is viewed expanded
    public var directories: [Directory]?
    
    /// An array of file descriptors that are assosciated with this directory
    public var attachments: [FileDescriptor]?
    
    init?(with dictionary: [AnyHashable: Any]) {
        
        guard let identifier = dictionary["id"] as? Int else {
            return nil
        }
        
        parentIdentifier = dictionary["parentId"] as? Int
        
        self.identifier = identifier
        
        if let _order = dictionary["order"] as? Int {
            order = _order
        }
        
        metadata = dictionary["metadata"] as? [AnyHashable: Any]
        
        directoryTitle = dictionary["title"] as? String
        content = dictionary["content"] as? String
        
        if let _directories = dictionary["directories"] as? [[AnyHashable: Any]] {
            directories = _directories.flatMap({ Directory(with: $0)})
        }
        
        if let _fileDescriptors = dictionary["attachments"] as? [[AnyHashable: Any]] {
            attachments = _fileDescriptors.flatMap({ FileDescriptor(with: $0)})
        }
    }
}
