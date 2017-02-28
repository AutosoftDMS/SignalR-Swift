//
//  LongPollingTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire

public class LongPollingTransport: HttpTransport {
    var reconnectDelay = 5.0
    var errorDelay = 2.0
    private var pollingOperationQueue = OperationQueue()

    override init() {
        self.pollingOperationQueue.maxConcurrentOperationCount = 1
    }

    // MARK: - Client Transport Protocol

    override public var name: String? {
        return "longPolling"
    }

    override public var supportsKeepAlive: Bool {
        return false
    }

    override public func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        super.negotiate(connection: connection, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func start(connection: ConnectionProtocol, connectionData: String, completionHandler: ((Any?, Error?) -> ())?) {
        self.poll(connection: connection, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func send(connection: ConnectionProtocol, data: Any, connectionData: String, completionHandler: ((Any?, Error?) -> ())?) {
        super.send(connection: connection, data: data, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String) {
        super.abort(connection: connection, timeout: timeout, connectionData: connectionData)
    }

    override public func lostConnection(connection: ConnectionProtocol) {

    }

    // MARK: - Long Polling

    func poll(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((_ response: String?, _ error: Error?) -> ())?) {
        var canReconnect = true

        var url = connection.url
        if connection.messageId == nil {
            url = url.appending("connect")
        } else if self.isConnectionReconnecting(connection: connection) {
            url = url.appending("reconnect")
        } else {
            url = url.appending("poll")
        }

        self.delayConnectionReconnect(connection: connection, canReconnect: &canReconnect)

        weak var weakConnection = connection

        var parameters: [String: Any] = [
            "transport": self.name!,
            "connectionToken": connection.connectionToken ?? "",
            "connectionData": connectionData ?? "",
            "groupsToken": connection.groupsToken ?? "",
            "messageId": connection.messageId ?? ""
        ]

        if let queryString = connection.queryString {
            for key in queryString.keys {
                parameters[key] = queryString[key]
            }
        }

        self.pollingOperationQueue.addOperation {
            let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters, timeout: 240)
            encodedRequest.validate().responseJSON { [unowned self] (response) in
                switch response.result {
                case .success(let result):

                    let strongConnection = weakConnection
                    var shouldReconnect = false
                    var disconnectedReceived = false

                    strongConnection?.processResponse(response: result, shouldReconnect: &shouldReconnect, disconnected: &disconnectedReceived)

                    if let handler = completionHandler {
                        handler(nil, nil)
                    }

                    if self.isConnectionReconnecting(connection: strongConnection!) {
                        self.connectionReconnect(connection: strongConnection!, canReconnect: canReconnect)
                    }

                    if shouldReconnect {
                        _ = Connection.ensureReconnecting(connection: strongConnection)
                    }

                    if disconnectedReceived {
                        strongConnection?.disconnect()
                    }

                    if !self.tryCompleteAbort() {
                        canReconnect = true
                        self.poll(connection: strongConnection!, connectionData: connectionData, completionHandler: nil)
                    }
                case .failure(let error):
                    let strongConnection = weakConnection
                    canReconnect = false

                    _ = Connection.ensureReconnecting(connection: connection)

                    if !self.tryCompleteAbort() && ExceptionHelper.isRequestAborted(error: (error as NSError)) {
                        strongConnection?.didReceiveError(error: error)

                        canReconnect = true

                        _ = BlockOperation(block: {
                            self.poll(connection: strongConnection!, connectionData: connectionData, completionHandler: nil)
                        }).perform(#selector(BlockOperation.start), with: nil, afterDelay: self.errorDelay)
                    } else {
                        self.completeAbort()
                        if let handler = completionHandler {
                            handler(nil, error)
                        }
                    }
                }
            }
        }
    }

    func delayConnectionReconnect(connection: ConnectionProtocol, canReconnect: inout Bool) {
        if self.isConnectionReconnecting(connection: connection) {
            let canReconnectCopy = canReconnect
            if canReconnect {
                canReconnect = false

                _ = BlockOperation(block: { [unowned self] in
                    self.connectionReconnect(connection: connection, canReconnect: canReconnectCopy)
                }).perform(#selector(BlockOperation.start), with: nil, afterDelay: self.reconnectDelay)
            }
        }
    }

    func connectionReconnect(connection: ConnectionProtocol, canReconnect: Bool) {
        if canReconnect {
            if connection.changeState(oldState: .reconnecting, toState: .connected) {
                connection.didReconnect()
            }
        }
    }

    func isConnectionReconnecting(connection: ConnectionProtocol) -> Bool {
        return connection.state == .reconnecting
    }
}
