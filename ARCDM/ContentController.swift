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
    private let requestController = TSCRequestController(baseAddress: "https://cie.arc.cubeapis.com/api/")
    
    private var bundleDirectory: URL?
    private var documentsDirectory: URL?
    
    /// The timestamp of the bundle that is currently in use by the app. Returns 0 if there is not any
    public var currentBundleTimestamp: TimeInterval {
        return UserDefaults.standard.value(forKey: "CurrentBundleTimestamp") as? TimeInterval ?? 0
    }
    
    public init() {
        
        if let _bundlePath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last {
            
            let _bundleDirectory = URL(fileURLWithPath: _bundlePath, isDirectory: true).appendingPathComponent("CIEBundle")
            bundleDirectory = _bundleDirectory
            
            //Create application support directory
            do {
                try FileManager.default.createDirectory(atPath: _bundleDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("<ARCDMS> [CRITICAL ERROR] Failed to create bundle directory at \(_bundleDirectory)")
            }
        }
        
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    }
    
    /// Retrieves information about the latest bundle/publish for a project. This can be used to compare the current bundle and determine if there is an update available
    ///
    /// - Parameters:
    ///   - projectID: The project ID to look up the bundle information for
    ///   - completion: A Result<BundleInformation> object that contains either the bundle information or an error where appropriate.
    public func getBundleInformation(for projectID: String, completion: @escaping (Result<BundleInformation>) -> Void) {
        
        requestController.get("projects/\(projectID)/publishes/latest") { (response, error) in
            
            guard let bundleInformationDictionary = response?.dictionary else {
                completion(Result(value: nil, error: error))
                return
            }
            
            let bundleInformation = BundleInformation(with: bundleInformationDictionary)
            
            completion(Result(value: bundleInformation, error: error))
        }
    }
    
    /// Downloads a bundle for the given project and unpacks it for use.
    ///
    /// - Parameters:
    ///   - url: The URL of the bundle to download. This can be a redirecting URL if appropriate as redirects will be followed
    ///   - progress: An optional `TSCRequestProgressHandler`. Download progress and file size will be reported through this closure.
    ///   - completion: A Result<Bool> object where the Bool indicates success or failure of downloading the file. Please note that this may return nil for the boolean if an error object is present as the error is more descriptive.
    public func downloadBundle(from url: URL, progress: @escaping TSCRequestProgressHandler, completion: @escaping (Result<Bool>) -> Void) {
        
        requestController.downloadFile(withPath: url.absoluteString, progress: progress) { (fileLocation, error) in
            
            if let _error = error {
                completion(Result(value: nil, error: _error))
                return
            }
            
            if let _fileLocation = fileLocation {
                
                //Unpack
                if let _bundleDirectory = self.bundleDirectory {
                    self.unpackBundle(file: _fileLocation, to: _bundleDirectory)
                }
                
                completion(Result(value: true, error: nil))
                return
            }
            
            completion(Result(value: false, error: nil))
        }
    }
    
    public func downloadDocumentFile(from url: URL, progress: @escaping TSCRequestProgressHandler, completion: @escaping (Result<URL>) -> Void) {
        
        requestController.downloadFile(withPath: url.absoluteString, progress: progress) { (fileLocation, error) in
            
            if let _error = error {
                completion(Result(value: nil, error: _error))
                return
            }
            
            if let _fileLocation = fileLocation, let _documentsDirectory = self.documentsDirectory {
                
                let newFilePath = _documentsDirectory.appendingPathComponent(url.lastPathComponent)
                
                try? FileManager.default.moveItem(at: _fileLocation, to: newFilePath)
                
                completion(Result(value: newFilePath, error: nil))
                return
            }
            completion(Result(value: nil, error: nil))
        }
    }
    
    private func deleteContents(of directory: URL) {
        
        let fm = FileManager.default
        var files: [String] = []
        
        do {
            files = try fm.contentsOfDirectory(atPath: directory.path)
        } catch let error {
            print("<ARCDMS> Failed to get files for removing bundle in directory at path: \(directory), error: \(error.localizedDescription)")
        }
        
        files.forEach { (filePath) in
            
            do {
                try fm.removeItem(at: directory.appendingPathComponent(filePath))
            } catch let error {
                print("<ARCDMS> Failed to remove file at path: \(directory)/\(filePath), error: \(error.localizedDescription)")
            }
        }
    }
    
    private func unpackBundle(file: URL, to destinationDirectory: URL) {
        
        //Rename
//        let newURL = file.deletingPathExtension().appendingPathExtension("tar.gz")
//        try? FileManager.default.moveItem(at: file, to: newURL)
        
        //Clear out existing files
        deleteContents(of: destinationDirectory)
        
        
        //
        var data: Data
        
        // Read data from directory
        do {
            data = try Data(contentsOf: file, options: Data.ReadingOptions.mappedIfSafe)
        } catch let error {
            print("<ARCDMS> [Updates] Unpacking bundle failed \(error.localizedDescription)")
            return
        }
        
        let archive = "data.tar"
        let nsData = data as NSData
        
        // Unzip data
        let gunzipData = gunzip(nsData.bytes, nsData.length)
        
        let cDecompressed = Data(bytes: gunzipData.data, count: gunzipData.length)
        
        //Write unzipped data to directory
        let directoryWriteUrl = destinationDirectory.appendingPathComponent(archive)
        
        do {
            try cDecompressed.write(to:directoryWriteUrl, options: [])
        } catch let error {
            print("<ARCDMS> [Updates] Writing unpacked bundle failed: \(error.localizedDescription)")
            return
        }
        
        // We bridge to Objective-C here as the untar doesn't like switch CString struct
        let arch = fopen((destinationDirectory.appendingPathComponent(archive).path as NSString).cString(using: String.Encoding.utf8.rawValue), "r")
        
        untar(arch, (destinationDirectory.path as NSString).cString(using: String.Encoding.utf8.rawValue))
        
        fclose(arch)
        
        //Clean up
        try? FileManager.default.removeItem(at: destinationDirectory.appendingPathComponent(archive))
    }
    
    /// Returns the file url of a file in the bundle
    ///
    /// - parameter forResource:   The name of the file, excluding it's file extension
    /// - parameter withExtension: The file extension to look up
    /// - parameter inDirectory:   A specific directory inside of the bundle to lookup (Optional)
    ///
    /// - returns: Returns a url for the resource if it's found
    public func fileUrl(forResource: String, withExtension: String, inDirectory: String?) -> URL? {
        
        var bundleFile: URL?
        
        if let bundleDirectory = bundleDirectory {
            
            if let _inDirectory = inDirectory {
                bundleFile = bundleDirectory.appendingPathComponent(_inDirectory).appendingPathComponent(forResource).appendingPathExtension(withExtension)
            } else {
                bundleFile = bundleDirectory.appendingPathComponent(forResource).appendingPathExtension(withExtension)
            }
        }
        
        if let _bundleFile = bundleFile, FileManager.default.fileExists(atPath: _bundleFile.path) {
            return _bundleFile
        }
        
        return nil
    }
    
    /// Provides a file URL for a file from a content path
    ///
    /// - Parameter contentPath: The content path, provided by the `content` property on a `Module` object
    /// - Returns: A content path as a URL if one was found. nil if not.
    public func fileUrl(from contentPath: String) -> URL? {
        
        var bundleFile: URL?
        
        if let bundleDirectory = bundleDirectory {
            bundleFile = bundleDirectory.appendingPathComponent(contentPath)
        }
        
        if let _bundleFile = bundleFile, FileManager.default.fileExists(atPath: _bundleFile.path) {
            return _bundleFile
        }
        
        return nil
    }
    
    public func localFileURL(for remoteURL: URL) -> URL? {
        
        if let filePath = documentsDirectory?.appendingPathComponent(remoteURL.lastPathComponent) {
            if FileManager.default.fileExists(atPath: filePath.path) {
                return filePath
            }
        }
        return nil
    }
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
    
    /// A failable initialiser that takes a dictionary from the server and turns it into a readable object containing information about an available bundle
    ///
    /// - Parameter dictionary: A complete dictionary from the bundle information endpoint
    init?(with dictionary: [AnyHashable: Any]) {
        
        guard let dataDictionary = dictionary["data"] as? [AnyHashable: Any] else {
            return nil
        }
        
        identifier = dataDictionary["id"] as? String
        
        if let _dateString = dataDictionary["publish_date"] as? String {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
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
