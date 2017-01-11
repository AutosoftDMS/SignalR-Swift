//
//  ConnectionDelegate.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

protocol ConnectionDelegate: class {
    func connectionDidOpen(connection: ConnectionProtocol)
    func connectionDidClose(connection: ConnectionProtocol)
    func connectionWillReconnect(connection: ConnectionProtocol)
    func connectionDidReconnect(connection: ConnectionProtocol)
    func connection(connection: ConnectionProtocol, didReceiveData data: Any)
    func connection(connection: ConnectionProtocol, didReceiveError error: Error)
    func connection(connection: ConnectionProtocol, didChangeState oldState: ConnectionState, newState: ConnectionState)
    func connectionDidSlow(connection: ConnectionProtocol)
}
