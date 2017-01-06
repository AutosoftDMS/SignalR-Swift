//
//  ClientTransportProtocol.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

protocol ClientTransportProtocol {
    func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: (() -> ()), error: Error)
}
