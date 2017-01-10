//
//  WebSocketTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper
import Starscream
import Alamofire

typealias WebSocketStartClosure = ((_ response: String?, _ error: Error?) -> ())

class WebSocketTransport: HttpTransport, WebSocketDelegate {
    var reconnectDelay = 2.0
    private var connectionInfo: WebSocketConnectionInfo?
    private var webSocket: WebSocket?
    private var startClosure: WebSocketStartClosure?

    override var name: String? {
        return "webSockets"
    }

    override var supportsKeepAlive: Bool {
        return true
    }

    override func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        super.negotiate(connection: connection, connectionData: connectionData, completionHandler: completionHandler)
    }

    override func start(connection: ConnectionProtocol, connectionData: String, completionHandler: ((String?, Error?) -> ())?) {
        self.connectionInfo = WebSocketConnectionInfo(connection: connection, data: connectionData)

        // perform connection
        self.performConnect(completionHandler: completionHandler)
    }

    override func send<T>(connection: ConnectionProtocol, data: T, connectionData: String, completionHandler: ((String?, Error?) -> ())?) where T : Mappable {
        self.webSocket?.write(string: data.toJSONString()!)

        if let handler = completionHandler {
            handler(nil, nil)
        }
    }

    override func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String) {
        self.stopWebSocket()
        super.abort(connection: connection, timeout: timeout, connectionData: connectionData)
    }

    override func lostConnection(connection: ConnectionProtocol) {
        self.stopWebSocket()

        if self.tryCompleteAbort() {
            return
        }

        self.reconnect(connection: self.connectionInfo?.connection)
    }

    private func stopWebSocket() {
        self.webSocket?.delegate = nil
        self.webSocket?.disconnect()
        self.webSocket = nil
    }

    // MARK: - WebSockets transport

    func performConnect(completionHandler: ((_ response: String?, _ error: Error?) -> ())?) {
        self.performConnect(reconnecting: false, completionHandler: completionHandler)
    }

    func performConnect(reconnecting: Bool, completionHandler: ((_ response: String?, _ error: Error?) -> ())?) {
        let connection = self.connectionInfo?.connection
        var parameters: [String: Any] = [
            "transport": self.name ?? "",
            "connectionToken": connection?.connectionToken ?? "",
            "messageId": connection?.messageId ?? "",
            "groupsToken": connection?.groupsToken ?? "",
            "connectionData": self.connectionInfo?.data ?? ""
        ]

        if let queryString = self.connectionInfo?.connection?.queryString {
            for key in queryString.keys {
                parameters[key] = queryString[key]
            }
        }

        let url = reconnecting ? "reconnect" : "connect"

        let request = connection?.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.queryString, parameters: parameters)

        self.startClosure = completionHandler
        if let startClosure = self.startClosure {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Connection timed out.", comment: "timeout error description"),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("Connection did not receive initialized message before the timeout.", comment: "timeout error reason"),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Retry or switch transports.", comment: "timeout error retry suggestion")
            ]
            let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: self))", code: NSURLErrorTimedOut, userInfo: userInfo)
            self.stopWebSocket()

            startClosure(nil, error)
            self.startClosure = nil
        }

        self.webSocket = WebSocket(url: request!.request!.url!)
        self.webSocket?.delegate = self
        self.webSocket?.connect()
    }

    func reconnect(connection: ConnectionProtocol?) {
        _ = BlockOperation { [unowned self] () -> () in
            if Connection.ensureReconnecting(connection: connection) {
                self.performConnect(reconnecting: true, completionHandler: nil)
            }
            }.perform(#selector(BlockOperation.start), with: nil, afterDelay: self.reconnectDelay)
    }

    // MARK: - WebSocketDelegate

    func websocketDidConnect(socket: WebSocket) {
        if let connection = self.connectionInfo?.connection, connection.changeState(oldState: .reconnecting, toState: .connected) {
            connection.didReconnect()
        }
    }

    func websocketDidReceiveData(socket: WebSocket, data: Data) { }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        var timedOut = false
        var disconnected = false

        if var connection = self.connectionInfo?.connection {
            self.processResponse(connection: &connection, response: text, shouldReconnect: &timedOut, disconnected: &disconnected)
        }
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if self.tryCompleteAbort() {
            return
        }

        self.reconnect(connection: self.connectionInfo?.connection)
    }
}
