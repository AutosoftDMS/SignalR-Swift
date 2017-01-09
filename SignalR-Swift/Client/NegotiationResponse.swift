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
    var disconnectTimeout = 0.0
    var tryWebSockets = false

    var keepAliveTimeout: Double?
    var transportConnectTimeout: Double?

    init(dict: [String: Any]) {
        self.connectionId = dict[kConnectionId] as! String
        self.connectionToken = dict[kConnectionToken] as! String
        self.url = dict[kUrl] as! String
        self.protocolVersion = dict[kProtocolVersion] as! String
        self.disconnectTimeout = dict[kDisconnectTimeout] as! Double
        self.tryWebSockets = dict[kTryWebSockets] as! Bool

        if let keepAlive = dict[kKeepAliveTimeout] as? Double {
            self.keepAliveTimeout = keepAlive
        }

        if let transportConnect = dict[kTransportConnectTimeout] as? Double {
            self.transportConnectTimeout = transportConnect
        }
    }
}
