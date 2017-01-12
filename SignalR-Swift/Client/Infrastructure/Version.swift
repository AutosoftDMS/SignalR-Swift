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

public class Version : Equatable, CustomStringConvertible, Mappable {
    var build = 0
    var major = 0
    var majorRevision = 0
    var minor = 0
    var minorRevision = 0
    var revision = 0

    required public init?(map: Map) {

    }

    public func mapping(map: Map) {
        build <- map["build"]
        major <- map["major"]
        majorRevision <- map["majorRevision"]
        minor <- map["minor"]
        minorRevision <- map["minorRevision"]
        revision <- map["revision"]
    }

    init() {

    }

    init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }

    init(major: Int, minor: Int, build: Int) {
        self.major = major
        self.minor = minor
        self.build = build
    }

    init(major: Int, minor: Int, build: Int, revision: Int) {
        self.major = major
        self.minor = minor
        self.build = build
        self.revision = revision
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
                case 2:
                    tempVersion.build = intComponent
                case 3:
                    tempVersion.revision = intComponent
                default:
                    break
                }
            }
            version = tempVersion
        }

        return true
    }

    public static func == (lhs: Version, rhs: Version) -> Bool {
        return (lhs.major == rhs.major) && (lhs.minor == rhs.minor) && (lhs.build == rhs.build) && (lhs.revision == rhs.revision)
    }

    public var description: String {
        return "\(self.major).\(self.minor).\(self.build).\(self.revision)"
    }
}
