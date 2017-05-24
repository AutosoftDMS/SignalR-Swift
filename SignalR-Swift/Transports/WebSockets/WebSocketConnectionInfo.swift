//
//  WebSocketConnectionInfo.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

class WebSocketConnectionInfo {
    weak var connection: ConnectionProtocol?
    var data: String?

    init(connection: ConnectionProtocol, data: String?) {
        self.connection = connection
        self.data = data
    }
}
