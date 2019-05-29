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
public class ContentManager {
    
    /// The latest cached bundle information, this must be set externally as this SDK will not cache it automatically
    public var cachedBundleInformation: BundleInformation? {
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: "CachedBundleInfo")
                return
            }
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            UserDefaults.standard.set(data, forKey: "CachedBundleInfo")
        }
        get {
            guard let data = UserDefaults.standard.data(forKey: "CachedBundleInfo") else { return nil }
            return try? JSONDecoder().decode(BundleInformation.self, from: data)
        }
    }
    
    /// The network request controller for the DMSSDK module. Responsible for handling the download of bundles and related files
    private let requestController = TSCRequestController(baseAddress: Bundle.main.infoDictionary?["DMSSDKBaseURL"] as? String)
    
    /// The path to the bundle directory that contains the bundle from the DMS. Please note that this does not mean that the directory actually contains a bundle
    private var bundleDirectory: URL?
    
    /// The path to the directory that contains any documents that have been downloaded by the framework
    private var documentsDirectory: URL?
    
    /// The timestamp of the bundle that is currently in use by the app. Returns 0 if there is not any
    public var currentBundleTimestamp: TimeInterval {
        return UserDefaults.standard.value(forKey: "CurrentBundleTimestamp") as? TimeInterval ?? 0
    }
    
    /// Initialises the content controller and creates the directories for the bundle if they are missing
    public init() {
        
        if let _bundlePath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last {
            
            let _bundleDirectory = URL(fileURLWithPath: _bundlePath, isDirectory: true).appendingPathComponent("CIEBundle")
            bundleDirectory = _bundleDirectory
            
            //Create application support directory
            do {
                try FileManager.default.createDirectory(atPath: _bundleDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("<DMSSDK> [CRITICAL ERROR] Failed to create bundle directory at \(_bundleDirectory)")
            }
        }
        
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    }
    
    /// Retrieves information about the latest bundle/publish for a project. This can be used to compare the current bundle and determine if there is an update available
    ///
    /// - Parameters:
    ///   - projectID: The project ID to look up the bundle information for
    ///   - language: The language code to check for a new bundle. If this is not supplied it will check against the default language as set by the DMS
    ///   - completion: A Result<BundleInformation> object that contains either the bundle information or an error where appropriate.
    public func getBundleInformation(for projectID: String, language: String?, completion: @escaping (Result<BundleInformation>) -> Void) {
        
        var informationURLString = "projects/\(projectID)/publishes/latest"
        
        if let language = language {
            informationURLString = informationURLString.appending("?language=\(language)")
        }
        
        requestController.get(informationURLString) { (response, error) in
            
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
    ///
    /// - Warning:
    /// Calling this method will remove the existing bundle completely and replace it with the newly downloaded bundle.
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
    
    /// Downloads the file from a given url and stores it in the `Documents` directory for the app
    ///
    /// - Parameters:
    ///   - url: The URL of the file to download. This should be the full URL to the .ppt, .docx, .pdf, etc.
    ///   - progress: A closure that will periodically be called with an update on the progress of the file download
    ///   - completion: A closure to be called once the download completes. This will be called for both success or failure with a `Result` object
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
            print("<DMSSDK> Failed to get files for removing bundle in directory at path: \(directory), error: \(error.localizedDescription)")
        }
        
        files.forEach { (filePath) in
            
            do {
                try fm.removeItem(at: directory.appendingPathComponent(filePath))
            } catch let error {
                print("<DMSSDK> Failed to remove file at path: \(directory)/\(filePath), error: \(error.localizedDescription)")
            }
        }
    }
    
    private func unpackBundle(file: URL, to destinationDirectory: URL) {

        //Clear out existing files
        deleteContents(of: destinationDirectory)

        var data: Data
        
        // Read data from directory
        do {
            data = try Data(contentsOf: file, options: Data.ReadingOptions.mappedIfSafe)
        } catch let error {
            print("<DMSSDK> [Updates] Unpacking bundle failed \(error.localizedDescription)")
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
            print("<DMSSDK> [Updates] Writing unpacked bundle failed: \(error.localizedDescription)")
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
    /// - Parameter contentPath: The content path, provided by the `content` property on a `Directory` object
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
    
    /// Checks the local disk to see if we have already downloaded a file for a remote URL.
    ///
    /// - Parameter remoteURL: The full remote URL of the document to check for
    /// - Returns: The local file URL for the remote file, if it exists. Returns nil if it is not available locally.
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

extension BundleInformation: Codable {
    
}

/// An enum representing possible errors that may occur when attempting to download bundle data
public enum BundleError: Error {
    /** The server returned an invalid response that could not be parsed into useful data */
    case InvalidDataReturned
}
