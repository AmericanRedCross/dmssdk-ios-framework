//
//  DirectoryManagerTests.swift
//  DMSSDKTests
//
//  Created by Matthew Cheetham on 17/10/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import XCTest
@testable import DMSSDK

class DirectoryManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        //Create our directory and add the dummy structure json to work with
        if let _bundlePath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last {
            
            let _bundleDirectory = URL(fileURLWithPath: _bundlePath, isDirectory: true).appendingPathComponent("CIEBundle")
            
            guard FileManager.default.fileExists(atPath: _bundleDirectory.appendingPathComponent("structure.json").path) == false else {
                return
            }
            
            //Create application support directory
            do {
                try FileManager.default.createDirectory(atPath: _bundleDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("<DMSSDK> [CRITICAL ERROR] Failed to create bundle directory at \(_bundleDirectory)")
            }
            
            let structurePath = Bundle.init(for: DirectoryManagerTests.self).path(forResource: "structure", ofType: "json")
            
            if let structurePath = structurePath {
                do {
                    try FileManager.default.copyItem(at: URL(fileURLWithPath: structurePath), to: _bundleDirectory.appendingPathComponent("structure.json"))
                } catch {
                    print("<DMSSDK> [CRITICAL ERROR] Failed to copy strucutre.json to Application Support directory")
                }
            }
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCreateDirectoryManagerWithDefaultStructure() {
        
        let manager = DirectoryManager()
        XCTAssertNotNil(manager)
        XCTAssertNotNil(manager.directories)
        if let count = manager.directories?.count {
            XCTAssertEqual(count, 2)
        }
    }
}
