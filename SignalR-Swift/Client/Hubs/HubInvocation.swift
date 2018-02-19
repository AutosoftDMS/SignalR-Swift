//
//  HubInvocation.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

private let kCallbackId = "I"
private let kHub = "H"
private let kMethod = "M"
private let kArgs = "A"
private let kState = "S"

struct HubInvocation {

    let callbackId: String
    let hub: String
    let method: String
    let args: [Any]
    let state: [String: Any]
    
    init(callbackId: String, hub: String, method: String, args: [Any], state: [String: Any] = [:]) {
        self.callbackId = callbackId
        self.hub = hub
        self.method = method
        self.args = args
        self.state = state
    }
    
    init(jsonObject dict: [String: Any]) {
        callbackId = dict[kCallbackId] as? String ?? ""
        hub = dict[kHub] as? String ?? ""
        method = dict[kMethod] as? String ?? ""
        args = dict[kArgs] as? [Any] ?? []
        state = dict[kState] as? [String: Any] ?? [:]
    }

    func toJSONString() -> String? {
        let json: [String: Any] = [
            kCallbackId: callbackId,
            kHub: hub,
            kMethod: method,
            kArgs: args,
            kState: state
        ]
        return json.toJSONString()
    }
}
