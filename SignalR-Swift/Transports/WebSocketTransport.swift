//
//  WebSocketTransport.swift
//  SignalR-Swift
//
//
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Starscream
import Alamofire

private typealias WebSocketStartClosure = (String?, Error?) -> ()

public class WebSocketTransport: HttpTransport, WebSocketDelegate {
    var reconnectDelay = 2.0
    private var connectionInfo: WebSocketConnectionInfo?
    private var webSocket: WebSocket?
    private var startClosure: WebSocketStartClosure?
    private var connectTimeoutOperation: BlockOperation?
    
    public override init() {
        super.init()
    }
    
    override public var name: String? {
        return "webSockets"
    }
    
    override public var supportsKeepAlive: Bool {
        return true
    }
    
    override public func negotiate(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        super.negotiate(connection: connection, connectionData: connectionData, completionHandler: completionHandler)
    }
    
    override public func start(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        self.connectionInfo = WebSocketConnectionInfo(connection: connection, data: connectionData)
        
        // perform connection
        self.performConnect(completionHandler: completionHandler)
    }
    
    override public func send(connection: ConnectionProtocol, data: Any, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        if let dataString = data as? String {
            self.webSocket?.write(string: dataString)
        } else if let dataDict = data as? [String: Any] {
            self.webSocket?.write(string: dataDict.toJSONString()!)
        }
        
        completionHandler?(nil, nil)
    }
    
    override public func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String?) {
        self.stopWebSocket()
        super.abort(connection: connection, timeout: timeout, connectionData: connectionData)
    }
    
    override public func lostConnection(connection: ConnectionProtocol) {
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
            "transport": self.name!,
            "connectionToken": connection?.connectionToken ?? "",
            "messageId": connection?.messageId ?? "",
            "groupsToken": connection?.groupsToken ?? "",
            "connectionData": self.connectionInfo?.data ?? ""
        ]
        
        if let queryString = self.connectionInfo?.connection?.queryString {
            for (key, value) in queryString {
                parameters[key] = value
            }
        }
        
        var urlComponents = URLComponents(string: connection!.url)
        if let urlScheme = urlComponents?.scheme {
            if urlScheme.hasPrefix("https") {
                urlComponents?.scheme = "wss"
            } else if urlScheme.hasPrefix("http") {
                urlComponents?.scheme = "ws"
            }
        }
        
        do {
            self.startClosure = completionHandler
            if let startClosure = self.startClosure {
                self.connectTimeoutOperation = BlockOperation(block: { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Connection timed out.", comment: "timeout error description"),
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString("Connection did not receive initialized message before the timeout.", comment: "timeout error reason"),
                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Retry or switch transports.", comment: "timeout error retry suggestion")
                    ]
                    let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: strongSelf))", code: NSURLErrorTimedOut, userInfo: userInfo)
                    strongSelf.stopWebSocket()
                    strongSelf.startClosure = nil
                    startClosure(nil, error)
                })
                self.connectTimeoutOperation?.perform(#selector(BlockOperation.start), with: nil, afterDelay: connection!.transportConnectTimeout)
            }
            
            let baseUrl = try urlComponents?.asURL()
            let url = reconnecting ? baseUrl!.absoluteString.appending("reconnect") : baseUrl!.absoluteString.appending("connect")
            let request = connection?.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters, timeout: 30)
            
            request?.onURLRequestCreation(perform: { [weak self] urlRequest in
                guard let self = self else { return }
                self.webSocket = WebSocket(request: urlRequest, certPinner: FoundationSecurity(allowSelfSigned: connection?.webSocketAllowsSelfSignedSSL ?? true))
                self.webSocket!.delegate = self
                self.webSocket!.connect()
            })
        } catch {
            print("error: \(error)")
        }
    }
    
    func reconnect(connection: ConnectionProtocol?) {
        BlockOperation { [weak self] in
            if let strongSelf = self, let connection = connection, Connection.ensureReconnecting(connection: connection) {
                strongSelf.performConnect(reconnecting: true, completionHandler: nil)
            }
        }.perform(#selector(BlockOperation.start), with: nil, afterDelay: self.reconnectDelay)
    }
    
    // MARK: - WebSocketDelegate
    private func stopTimeOutOperation() {
        if let startClosure = self.startClosure, let connectTimeoutOperation = self.connectTimeoutOperation {
            NSObject.cancelPreviousPerformRequests(withTarget: connectTimeoutOperation, selector: #selector(BlockOperation.start), object: nil)
            self.connectTimeoutOperation = nil
            self.startClosure = nil
            startClosure(nil, nil)
        }
    }
    
    private func webSocketConnected(_ headers: [String: String]) {
        self.stopTimeOutOperation()
        if let connection = self.connectionInfo?.connection,
            connection.changeState(oldState: .reconnecting, toState: .connected) == true {
            connection.didReconnect()
        }
    }
    
    private func webSocketDisconnected(_ reason: String, _ code: UInt16) {
        if self.tryCompleteAbort() == false {
            self.reconnect(connection: self.connectionInfo?.connection)
        } else {
            self.connectionInfo?.connection?.disconnect()
            self.stopWebSocket()
        }
    }
    
    private func webSocketReceivedMessage(_ string: String) {
        var timedOut = false
        var disconnected = false
        if let connection = self.connectionInfo?.connection, let data = string.data(using: .utf8) {
            connection.processResponse(response: data, shouldReconnect: &timedOut, disconnected: &disconnected)
        }
    }
    
    private func webSocketError(_ error: Error?) {
        if self.startedAbort == false {
            self.reconnect(connection: self.connectionInfo?.connection)
        } else {
            self.stopTimeOutOperation()
            self.stopWebSocket()
        }
    }
    
    public func didReceive(event: WebSocketEvent, client: WebSocketClient) { 
        switch event {
        case .connected(let headers):
            //print("websocket is connected: \(headers)")
            webSocketConnected(headers)
        case .disconnected(let reason, let code):
            //print("websocket is disconnected: \(reason) with code: \(code)")
            webSocketDisconnected(reason, code)
        case .text(let string):
            //print("Received text: \(string)")
            webSocketReceivedMessage(string)
        case .binary(_):
            //print("Received data: \(data.count)")
            break
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            break;
        case .error(let error):
            print(error.debugDescription)
            webSocketError(error)
        }
    }
}

