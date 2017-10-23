//
//  LongPollingTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Alamofire

public class LongPollingTransport: HttpTransport {
    var reconnectDelay = 5.0
    var errorDelay = 2.0
    var pollingQueue = DispatchQueue(label: "com.autosoftdms.SignalR-Swift.serial")

    // MARK: - Client Transport Protocol

    override public var name: String? {
        return "longPolling"
    }

    override public var supportsKeepAlive: Bool {
        return false
    }

    override public func negotiate(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        super.negotiate(connection: connection, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func start(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        self.poll(connection: connection, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func send(connection: ConnectionProtocol, data: Any, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        super.send(connection: connection, data: data, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String?) {
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

        var parameters: [String: Any] = [
            "transport": self.name!,
            "connectionToken": connection.connectionToken ?? "",
            "connectionData": connectionData ?? "",
            "groupsToken": connection.groupsToken ?? "",
            "messageId": connection.messageId ?? ""
        ]

        if let queryString = connection.queryString {
            for (key, value) in queryString {
                parameters[key] = value
            }
        }

        let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters, timeout: 240)

        _ = self.pollingQueue.sync {
            encodedRequest.validate().responseData(completionHandler: { [weak self, weak connection] response in
                guard let strongSelf = self, let strongConnection = connection else { return }

                switch response.result {
                case .success(let result):

                    var shouldReconnect = false
                    var disconnectedReceived = false

                    strongConnection.processResponse(response: result, shouldReconnect: &shouldReconnect, disconnected: &disconnectedReceived)

                    if let handler = completionHandler {
                        handler(nil, nil)
                    }

                    if strongSelf.isConnectionReconnecting(connection: strongConnection) {
                        strongSelf.connectionReconnect(connection: strongConnection, canReconnect: canReconnect)
                    }

                    if shouldReconnect {
                        _ = Connection.ensureReconnecting(connection: strongConnection)
                    }

                    if disconnectedReceived {
                        strongConnection.disconnect()
                    }

                    if !strongSelf.tryCompleteAbort() {
                        canReconnect = true
                        strongSelf.poll(connection: strongConnection, connectionData: connectionData, completionHandler: nil)
                    }
                case .failure(let error):
                    canReconnect = false

                    _ = Connection.ensureReconnecting(connection: strongConnection)

                    if !strongSelf.tryCompleteAbort() && !ExceptionHelper.isRequestAborted(error: (error as NSError)) {
                        strongConnection.didReceiveError(error: error)

                        canReconnect = true

                        _ = BlockOperation(block: {
                            strongSelf.poll(connection: strongConnection, connectionData: connectionData, completionHandler: nil)
                        }).perform(#selector(BlockOperation.start), with: nil, afterDelay: strongSelf.errorDelay)
                    } else {
                        strongSelf.completeAbort()
                        if let handler = completionHandler {
                            handler(nil, error)
                        }
                    }
                }
            })
        }
    }

    func delayConnectionReconnect(connection: ConnectionProtocol, canReconnect: inout Bool) {
        if self.isConnectionReconnecting(connection: connection) {
            let canReconnectCopy = canReconnect
            if canReconnect {
                canReconnect = false

                _ = BlockOperation(block: { [weak self, weak connection] in
                    guard let strongSelf = self, let strongConnection = connection else { return }
                    strongSelf.connectionReconnect(connection: strongConnection, canReconnect: canReconnectCopy)
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
