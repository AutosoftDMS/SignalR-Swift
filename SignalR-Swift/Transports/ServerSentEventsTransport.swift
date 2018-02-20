//
//  ServerSentEventsTransport.swift
//  SignalR-Swift
//
//  Created by Vladimir Kushelkov on 19/07/2017.
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Alamofire

private typealias CompletionHandler = (_ respomce: Any?, _ error: Error?) -> ()

public class ServerSentEventsTransport: HttpTransport {
    private var stop = false
    private var connectTimeoutOperation: BlockOperation?
    private var completionHandler: CompletionHandler?
    private let sseQueue = DispatchQueue(label: "com.autosoftdms.SignalR-Swift.serverSentEvents", qos: .userInitiated)
    
    var reconnectDelay: TimeInterval = 2.0
    
    override public var name: String? {
        return "serverSentEvents"
    }
    
    override public var supportsKeepAlive: Bool {
        return true
    }
    
    override public func negotiate(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        super.negotiate(connection: connection, connectionData: connectionData, completionHandler: nil)
    }
    
    override public func start(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        self.completionHandler = completionHandler
        
        self.connectTimeoutOperation = BlockOperation { [weak self] in
            guard let strongSelf = self, let completionHandler = strongSelf.completionHandler else { return }
            
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Connection timed out.", comment: "timeout error description"),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("Connection did not receive initialized message before the timeout.", comment: "timeout error reason"),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Retry or switch transports.", comment: "timeout error retry suggestion")
            ]
            let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: strongSelf))", code: NSURLErrorTimedOut, userInfo: userInfo)
            completionHandler(nil, error)
            strongSelf.completionHandler = nil
        }
        
        self.connectTimeoutOperation!.perform(#selector(BlockOperation.start), with: nil, afterDelay: connection.transportConnectTimeout)
        
        self.open(connection: connection, connectionData: connectionData, isReconnecting: false)
    }
    
    override public func send(connection: ConnectionProtocol, data: Any, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        super.send(connection: connection, data: data, connectionData: connectionData, completionHandler: completionHandler)
    }
    
    override public func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String?) {
        self.stop = true
        super.abort(connection: connection, timeout: timeout, connectionData: connectionData)
    }
    
    override public func lostConnection(connection: ConnectionProtocol) {

    }
    
    // MARK: - SSE Transport
    
    private let buffer = ChunkBuffer()
    
    private func open(connection: ConnectionProtocol, connectionData: String?, isReconnecting: Bool) {
        var parameters = connection.queryString ?? [:]
        parameters["transport"] = self.name!
        parameters["connectionToken"] = connection.connectionToken ?? ""
        parameters["messageId"] = connection.messageId ?? ""
        parameters["groupsToken"] = connection.groupsToken ?? ""
        parameters["connectionData"] = connectionData ?? ""
        
        let url = isReconnecting ? connection.url.appending("reconnect") : connection.url.appending("connect")
        
        connection.getRequest(url: url,
                              httpMethod: .get,
                              encoding: URLEncoding.default,
                              parameters: parameters,
                              timeout: 240,
                              headers: ["Connection": "Keep-Alive"])
        .stream { [weak self] data in
            self?.sseQueue.async { [weak connection] in
                guard let strongSelf = self, let strongConnection = connection else { return }
                
                strongSelf.buffer.append(data: data)
                
                while let line = strongSelf.buffer.readLine() {
                    guard let message = ServerSentEvent.tryParse(line: line) else { continue }
                    DispatchQueue.main.async { strongSelf.process(message: message, connection: strongConnection) }
                }
            }
        }.validate().response() { [weak self, weak connection] dataResponse in
            guard let strongSelf = self, let strongConnection = connection else { return }
            
            strongSelf.cancelTimeoutOperation()
            
            if let error = dataResponse.error as NSError?, error.code != NSURLErrorCancelled {
                strongConnection.didReceiveError(error: error)
            }
            
            if strongSelf.stop {
                strongSelf.completeAbort()
            } else if !strongSelf.tryCompleteAbort() && !isReconnecting {
                strongSelf.reconnect(connection: strongConnection, data: connectionData)
            }
        }
    }
    
    private func process(message: ServerSentEvent, connection: ConnectionProtocol) {
        guard message.event == .data else { return }
        
        if message.data == "initialized" {
            if connection.changeState(oldState: .reconnecting, toState: .connected) {
                connection.didReconnect()
            }
            
            return
        }
        
        guard let data = message.data?.data(using: .utf8) else { return }
        
        var shouldReconnect = false
        var disconnected = false
        connection.processResponse(response: data, shouldReconnect: &shouldReconnect, disconnected: &disconnected)
        
        cancelTimeoutOperation()
        
        if disconnected {
            stop = true
            connection.disconnect()
        }
    }
    
    private func cancelTimeoutOperation() {
        guard let completionHandler = self.completionHandler,
            let timeoutOperation = connectTimeoutOperation else { return }
        
        NSObject.cancelPreviousPerformRequests(withTarget: timeoutOperation, selector: #selector(BlockOperation.start), object: nil)
        connectTimeoutOperation = nil
        completionHandler(nil, nil)
        self.completionHandler = nil
    }
    
    private func reconnect(connection: ConnectionProtocol, data: String?) {
        _ = BlockOperation { [weak self, weak connection] in
            if let strongSelf = self, let strongConnection = connection,
               strongConnection.state != .disconnected, Connection.ensureReconnecting(connection: strongConnection) {
                strongSelf.open(connection: strongConnection, connectionData: data, isReconnecting: true)
            }
        }.perform(#selector(BlockOperation.start), with: nil, afterDelay: self.reconnectDelay)
    }
}
