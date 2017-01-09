//
//  HttpTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

class HttpTransport: ClientTransportProtocol {

    var name: String! {
        return ""
    }

    var supportsKeepAlive: Bool {
        return false
    }

    func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: ((NegotiationResponse, Error?) -> ())) {

    }

    func start(connection: ConnectionProtocol, connectionData: String, completionHandler: ((AnyObject, Error?) -> ())) {

    }

    func send(connection: ConnectionProtocol, data: String, connectionData: String, completionHandler: ((AnyObject, Error?) -> ())) {

    }

    func completeAbort() {

    }

    func tryCompleteAbort() -> Bool {
        return false
    }

    func lostConnection(connection: ConnectionProtocol) {

    }

    func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String) {

    }

    func connectionParameters(connection: ConnectionProtocol, connectionData: String) {

    }


}
