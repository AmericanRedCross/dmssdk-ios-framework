//
//  Utilities.swift
//  Cash In Emergencies
//
//  Created by Matthew Cheetham on 25/08/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

/** An enum of errors that might occur while loading a result*/
public enum ResultError: Error {
    /** The method did not return a value or an error. Something went wrong */
    case InvalidInputOrMethodFailure
}

/// A generic enum to restrict our methods to simply an error or a result
///
/// - success: The value if we are successful
/// - failure: The error object if we fail
public enum Result<T> {
    case success(T)
    case failure(Error)
}

public extension Result {
    
    /// Initializes a Result from an optional success value and an optional error. Useful for converting return values from many asynchronous Apple APIs to Result.
    init(value: T?, error: Error?) {
        
        switch (value, error) {
        case (let v?, _):
            self = .success(v)
        case (nil, let e?):
            self = .failure(e)
        case (nil, nil):
            self = .failure(ResultError.InvalidInputOrMethodFailure)
        }
    }
}
