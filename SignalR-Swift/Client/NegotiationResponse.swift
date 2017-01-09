//
//  NegotiationResponse.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper

private let kConnectionId = "ConnectionId"
private let kConnectionToken = "ConnectionToken"
private let kUrl = "Url"
private let kProtocolVersion = "ProtocolVersion"
private let kDisconnectTimeout = "DisconnectTimeout"
private let kTryWebSockets = "TryWebSockets"
private let kKeepAliveTimeout = "KeepAliveTimeout"
private let kTransportConnectTimeout = "TransportConnectTimeout"

class NegotiationResponse: Mappable {
    var connectionId = ""
    var connectionToken = ""

    var url = ""

    var protocolVersion = ""
    var disconnectTimeout = 0.0
    var tryWebSockets = false

    var keepAliveTimeout: Double?
    var transportConnectTimeout: Double?

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        connectionId <- map[kConnectionId]
        connectionToken <- map[kConnectionToken]
        url <- map[kUrl]
        protocolVersion <- map[kProtocolVersion]
        disconnectTimeout <- map[kDisconnectTimeout]
        tryWebSockets <- map[kTryWebSockets]
        keepAliveTimeout <- map[kKeepAliveTimeout]
        transportConnectTimeout <- map[kTransportConnectTimeout]
    }
}
