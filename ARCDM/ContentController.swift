//
//  ContentController.swift
//  Cash In Emergencies
//
//  Created by Matthew Cheetham on 25/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import Foundation
import ThunderRequest

/// A controller responsible for managing content and bundles. This includes facilitating the downloads and updates of new bundle content.
public class ContentController {
    
    /// The network request controller for the ARCDMS module. Responsible for handling the download of bundles and related files
    private let requestController = TSCRequestController(baseAddress: "http://ec2-54-193-52-173.us-west-1.compute.amazonaws.com/api/")
    
    public init() {}
    
    /// Retrieves information about the latest bundle/publish for a project. This can be used to compare the current bundle and determine if there is an update available
    ///
    /// - Parameters:
    ///   - projectID: The project ID to look up the bundle information for
    ///   - completion: A Result<BundleInformation> object that contains either the bundle information or an error where appropriate.
    public func getBundleInformation(for projectID: String, completion: @escaping (Result<BundleInformation>) -> Void) {
        
        requestController.get("projects/1/publishes/latest?language=en") { (response, error) in
            
            guard let bundleInformationDictionary = response?.dictionary else {
                completion(Result(value: nil, error: BundleError.InvalidDataReturned))
                return
            }
            
            let bundleInformation = BundleInformation(with: bundleInformationDictionary)
            
            
            completion(Result(value: nil, error: error))
            
            
        }
    }
    
    /// Downloads a bundle for the given project and unpacks it for use.
    ///
    /// - Parameters:
    ///   - projectID: The project ID to download the bundle for
    ///   - language: The language code to download the bundle for. Use `getBundleInformation(for:completion:)` to find the available language code
    ///   - completion: A Result<Bool> object where the boolean indicates success. This may also return an Error object where appropriate.
    func downloadBundle(for projectID: String, language: String, completion: @escaping (Result<Bool>) -> Void) {}
}

/// Contains information about an available storm bundle on the server
public struct BundleInformation {
    
    /// The bundle identifier as provided by the server
    public var identifier: String?
    /// The timedate that the bundle was created
    public var publishDate: Date?
    /// The URL to download the file (May be a redirect)
    public var downloadURL: URL?
    /// The language codes of the available languages
    public var availableLanguages: [String]?
    
    init?(with dictionary: [AnyHashable: Any]) {
        
        guard let dataDictionary = dictionary["data"] as? [AnyHashable: Any] else {
            return nil
        }
        
        identifier = dataDictionary["id"] as? String
        
        if let _dateString = dataDictionary["publish_date"] as? String {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            publishDate = dateFormatter.date(from: _dateString)
        }
        
        if let _downloadString = dataDictionary["download_url"] as? String {
            downloadURL = URL(string: _downloadString)
        }
        
        availableLanguages = dataDictionary["languages"] as? [String]
    }
}

public enum BundleError: Error {
    /** The server returned an invalid response that could not be parsed into useful data */
    case InvalidDataReturned
}
