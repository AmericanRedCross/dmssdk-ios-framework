//
//  FileDescriptor.swift
//  ARCDM
//
//  Created by Matthew Cheetham on 16/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

/// An object representing a file available at a URL
public struct FileDescriptor {
    
    /// The name of the file which can be displayed to a user
    public var title: String?
    
    /// The remote URL which can be used to access the file.
    public var url: URL?
    
    /// The mime type of the file
    public var mime: String?
    
    /// The size of the remote file in bytes
    public var size: Double?
    
    /// A description of the file to give a user more context before downloading
    public var description: String?
    
    /// Initialises a new FileDescriptor from a dictionary
    ///
    /// - Parameter dictionary: The dictionary entry loaded from a json file
    init(with dictionary: [AnyHashable: Any]) {
        
        title = dictionary["title"] as? String
        description = dictionary["description"] as? String
        
        if let _urlString = dictionary["url"] as? String {
            url = URL(string: _urlString)
        }
        
        mime = dictionary["mime"] as? String
        size = dictionary["size"] as? Double
    }
}
