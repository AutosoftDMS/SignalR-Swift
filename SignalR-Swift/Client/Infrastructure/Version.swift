//
//  Version.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper

public class Version : Equatable, CustomStringConvertible {
    var major = 0
    var minor = 0

    required public init?(map: Map) {

    }

    init() {

    }

    init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }

    static func parse(input: String?, forVersion version: inout Version?) -> Bool {

        if input == nil || input!.isEmpty {
            return false
        }

        if let components = input?.components(separatedBy: ".") {
            if components.count < 2 || components.count > 4 {
                return false
            }

            let tempVersion = Version()
            for (index, component) in components.enumerated() {
                let intComponent = Int(component)!
                switch index {
                case 0:
                    tempVersion.major = intComponent
                case 1:
                    tempVersion.minor = intComponent
                default:
                    break
                }
            }
            version = tempVersion
        }

        return true
    }

    public static func == (lhs: Version, rhs: Version) -> Bool {
        return (lhs.major == rhs.major) && (lhs.minor == rhs.minor)
    }

    public var description: String {
        return "\(self.major).\(self.minor)"
    }
}
