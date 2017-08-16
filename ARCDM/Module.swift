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
    public var identifier: String
    
    /// The position at which this module should be displayed when presented in a list
    public var hierarchy: Int = 0
    
    /// The title of the module
    public var title: String
    
    /// The raw markdown content of the module
    public var content: String
    
    /// An array of module objects which are steps to display beneath this module when it is viewed
    public var steps: [Module]?
    
    /// An array of file descriptors that are assosciated with this module
    public var attachments: [FileDescriptor]?
    
    /// If the module is marked as being a pert of the "Critical Path", this is true.
    public var critical: Bool = false
}
