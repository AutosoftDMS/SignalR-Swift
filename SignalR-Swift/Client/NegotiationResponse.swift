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

public struct NegotiationResponse {
    let connectionId: String
    let connectionToken: String
    let url: String
    let protocolVersion: String
    let disconnectTimeout: Double
    let tryWebSockets: Bool
    let keepAliveTimeout: Double?
    let transportConnectTimeout: Double?
    
    init(jsonObject dict: [String: Any]) {
        connectionId = dict[kConnectionId] as? String ?? ""
        connectionToken = dict[kConnectionToken] as? String ?? ""
        url = dict[kUrl] as? String ?? ""
        protocolVersion = dict[kProtocolVersion] as? String ?? ""
        disconnectTimeout = dict[kDisconnectTimeout] as? Double ?? 0.0
        tryWebSockets = dict[kTryWebSockets] as? Bool ?? false
        keepAliveTimeout = dict[kKeepAliveTimeout] as? Double
        transportConnectTimeout = dict[kTransportConnectTimeout] as? Double
    }
}
