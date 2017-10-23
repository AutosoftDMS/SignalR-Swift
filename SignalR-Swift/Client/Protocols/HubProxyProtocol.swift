//
//  HubProxyProtocol.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

public typealias Subscription = ([Any]) -> ()

protocol HubProxyProtocol {
    func on(eventName: String, handler: @escaping Subscription) -> Subscription?

    func invoke(method: String, withArgs args: [Any])

    func invoke(method: String, withArgs args: [Any], completionHandler: ((_ response: Any?, _ error: Error?) -> ())?)
}
