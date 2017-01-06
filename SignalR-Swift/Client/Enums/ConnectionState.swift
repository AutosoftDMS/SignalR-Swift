//
//  ConnectionState.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

enum ConnectionState : Int {
    case connecting
    case connected
    case reconnecting
    case disconnected
}
