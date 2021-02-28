//
//  Version.swift
//  BluetoothSerialPro
//
//  Created by Alex on 29-09-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//

import Foundation

// "final" to prevent errors of supposedly "required" ExpressibleByStringLiteral inits
final class Version: Comparable {
    
    // MARK: - Variables
    
    var major = 0,
    minor = 0,
    patch = 0
    
    var stringValue: String {
        get {
            return  "\(major).\(minor).\(patch)"
        } set {
            do { try interpretString(newValue) }
            catch { print("Version: Failed to set stringValue!") }
        }
    }
    
    
    // MARK: - Functions
    
    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    init(major: UInt8, minor: UInt8, patch: UInt8) {
        self.major = Int(major)
        self.minor = Int(minor)
        self.patch = Int(patch)
    }
    
    init(_ string: String) {
        do { try interpretString(string) }
        catch { print("Version: Failed to init with string '\(string)'") }
    }
    
    fileprivate func interpretString(_ str: String) throws {
        let regex = try NSRegularExpression(pattern: "([0-9]+).([0-9]+).([0-9]+)", options: .caseInsensitive)
        let range = NSMakeRange(0, str.count)
        
        major = Int(regex.stringByReplacingMatches(in: str, options: NSRegularExpression.MatchingOptions(), range: range, withTemplate: "$1"))!
        minor = Int(regex.stringByReplacingMatches(in: str, options: NSRegularExpression.MatchingOptions(), range: range, withTemplate: "$2"))!
        patch = Int(regex.stringByReplacingMatches(in: str, options: NSRegularExpression.MatchingOptions(), range: range, withTemplate: "$3"))!
    }
}


// MARK: - Comparable

func < (lhs: Version, rhs: Version) -> Bool {
    if lhs.major < rhs.major { return true }
    if lhs.major > rhs.major { return false }
    if lhs.minor < rhs.minor { return true }
    if lhs.minor > rhs.minor { return false }
    if lhs.patch < rhs.patch { return true }
    return false
}

func == (lhs: Version, rhs: Version) -> Bool {
    if lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch {
        return true
    } else {
        return false
    }
}


// MARK: - StringLiteralConvertible

extension Version: ExpressibleByStringLiteral {
    typealias UnicodeScalarLiteralType = StringLiteralType
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    convenience init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }
    
    convenience init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }
    
    convenience init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}
