//
//  NegotiationResponse.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

private let kConnectionId = "ConnectionId"
private let kConnectionToken = "ConnectionToken"
private let kUrl = "Url"
private let kProtocolVersion = "ProtocolVersion"
private let kDisconnectTimeout = "DisconnectTimeout"
private let kTryWebSockets = "TryWebSockets"
private let kKeepAliveTimeout = "KeepAliveTimeout"
private let kTransportConnectTimeout = "TransportConnectTimeout"

class NegotiationResponse {
    var connectionId = ""
    var connectionToken = ""

    var url = ""

    var protocolVersion = ""
    var disconnectTimeout = 0
    var tryWebSockets = false

    var keepAliveTimeout: Int?
    var transportConnectTimeout: Int?

    init(dict: [String: AnyObject]) {
        self.connectionId = dict[kConnectionId] as! String
        self.connectionToken = dict[kConnectionToken] as! String
        self.url = dict[kUrl] as! String
        self.protocolVersion = dict[kProtocolVersion] as! String
        self.disconnectTimeout = dict[kDisconnectTimeout] as! Int
        self.tryWebSockets = dict[kTryWebSockets] as! Bool

        if let keepAlive = dict[kKeepAliveTimeout] as? Int {
            self.keepAliveTimeout = keepAlive
        }

        if let transportConnect = dict[kTransportConnectTimeout] as? Int {
            self.transportConnectTimeout = transportConnect
        }
    }
}
