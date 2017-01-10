//
//  HubInvocation.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper

private let kCallbackId = "I"
private let kHub = "H"
private let kMethod = "M"
private let kArgs = "A"
private let kState = "S"

class HubInvocation: Mappable {
    var callbackId = ""
    var hub = ""
    var method = ""
    var args = [Any]()
    var state = [String: Any]()

    init() {

    }

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        callbackId <- map[kCallbackId]
        hub <- map[kHub]
        method <- map[kMethod]
        args <- map[kArgs]
        state <- map[kState]
    }
}
