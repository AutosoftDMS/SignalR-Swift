//
//  HttpTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class HttpTransport: ClientTransportProtocol {

    var name: String! {
        return ""
    }

    var supportsKeepAlive: Bool {
        return false
    }

    private var startedAbort = false

    func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: ((NegotiationResponse, Error?) -> ())) {

    }

    func start(connection: ConnectionProtocol, connectionData: String, completionHandler: ((Any, Error?) -> ())) {

    }

    func send(connection: ConnectionProtocol, data: String, connectionData: String, completionHandler: ((Any, Error?) -> ())) {

    }

    func completeAbort() {

    }

    func tryCompleteAbort() -> Bool {
        return false
    }

    func lostConnection(connection: ConnectionProtocol) {

    }

    func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String) {
        if timeout <= 0 {
            return
        }

        if !self.startedAbort {
            self.startedAbort = true

            let parameters = ConnectionParameters()
            parameters.clientProtocol = connection.version
            parameters.transport = self.name
            parameters.connectionData = connectionData
            parameters.connectionToken = connection.connectionToken
            parameters.queryString = connection.queryString

            let url = connection.url.appending("abort")

            // refactor this so that headers are common
            let request = connection.getRequest(url: url, httpMethod: .get, parameters: parameters.toJSON())

        }
    }
}
