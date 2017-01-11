//
//  HubProxyProtocol.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

protocol HubProxyProtocol {
    func on(eventName: String?, handler: @escaping ((_ args: [Any]) -> ())) -> Subscription?

    func invoke(method: String?, withArgs args: [Any])

    func invoke(method: String?, withArgs args: [Any], completionHandler: ((_ response: Any?, _ error: Error?) -> ())?)
}
