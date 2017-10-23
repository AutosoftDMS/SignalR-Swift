//
//  Version.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import UIKit

public struct Version : Equatable, CustomStringConvertible {
    let major: UInt
    let minor: UInt

    public init(major: UInt = 0, minor: UInt = 0) {
        self.major = major
        self.minor = minor
    }
    
    public init?(string input: String) {
        let components = input.components(separatedBy: ".")
        guard (2...4) ~= components.count, let major = UInt(components[0]), let minor = UInt(components[1]) else {
            return nil }
        
        self.major = major
        self.minor = minor
    }
    
    public static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor
    }

    public var description: String {
        return "\(self.major).\(self.minor)"
    }
}
