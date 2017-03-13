//
//  ClientTransportProtocol.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

public protocol ClientTransportProtocol {
    var name: String? { get }
    var supportsKeepAlive: Bool { get }
    func negotiate(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((_ response: NegotiationResponse?, _ error: Error?) -> ())?)
    func start(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((_ response: Any?, _ error: Error?) -> ())?)
    func send(connection: ConnectionProtocol, data: Any, connectionData: String?, completionHandler: ((_ response: Any?, _ error: Error?) -> ())?)

    func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String?)
    func lostConnection(connection: ConnectionProtocol)
}
