//
//  ConnectionDelegate.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

protocol ConnectionDelegate {
    func didOpen(connection: ConnectionProtocol)
    func willReconnect(connection: ConnectionProtocol)
    func didReconnect(connection: ConnectionProtocol)
    func connection(connection: ConnectionProtocol, didReceiveData data: Any)
    func connection(connection: ConnectionProtocol, didReceiveError error: Error)
    func connection(connection: ConnectionProtocol, didChangeState oldState: ConnectionState, newState: ConnectionState)
    func didSlow(connection: ConnectionProtocol)
}
