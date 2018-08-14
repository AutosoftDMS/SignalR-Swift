//
//  Connection.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

public typealias ConnectionStartedClosure = (() -> ())
public typealias ConnectionReceivedClosure = ((Any) -> ())
public typealias ConnectionErrorClosure = ((Error) -> ())
public typealias ConnectionClosedClosure = (() -> ())
public typealias ConnectionReconnectingClosure = (() -> ())
public typealias ConnectionReconnectedClosure = (() -> ())
public typealias ConnectionStateChangedClosure = ((ConnectionState) -> ())
public typealias ConnectionConnectionSlowClosure = (() -> ())

open class Connection: ConnectionProtocol {
    var defaultAbortTimeout = 30.0
    var assemblyVersion: Version?
    var disconnectTimeout: Double?
    var disconnectTimeoutOperation: BlockOperation!

    open var state = ConnectionState.disconnected
    open var url: String

    open var items = [String : Any]()
    open let queryString: [String: String]?

    var connectionData: String?
    var monitor: HeartbeatMonitor?

    open var version = Version(major: 1, minor: 3)

    open var connectionId: String?
    open var connectionToken: String?
    open var groupsToken: String?
    open var messageId: String?

    open var headers = HTTPHeaders()
    open var keepAliveData: KeepAliveData?
    open var webSocketAllowsSelfSignedSSL = false
    open internal(set) var sessionManager: SessionManager

    open var transport: ClientTransportProtocol?
    open var transportConnectTimeout = 0.0

    open var started: ConnectionStartedClosure?
    open var received: ConnectionReceivedClosure?
    open var error: ConnectionErrorClosure?
    open var closed: ConnectionClosedClosure?
    open var reconnecting: ConnectionReconnectingClosure?
    open var reconnected: ConnectionReconnectedClosure?
    open var stateChanged: ConnectionStateChangedClosure?
    open var connectionSlow: ConnectionConnectionSlowClosure?

    weak var delegate: ConnectionDelegate?

    static func ensureReconnecting(connection: ConnectionProtocol) -> Bool {
        if connection.changeState(oldState: .connected, toState: .reconnecting) {
            connection.willReconnect()
        }

        return connection.state == .reconnecting
    }

    public init(withUrl url: String, queryString: [String: String]? = nil, sessionManager: SessionManager = .default) {
        self.url = url.hasSuffix("/") ? url : url.appending("/")
        self.queryString = queryString
        self.sessionManager = sessionManager
    }

    // MARK: - Connection management

    open func start() {
        self.start(transport: AutoTransport())
    }

    open func start(transport: ClientTransportProtocol) {
        if !self.changeState(oldState: .disconnected, toState: .connecting) {
            return
        }

        self.monitor = HeartbeatMonitor(withConnection: self)
        self.transport = transport

        self.negotiate(transport: transport)
    }

    func negotiate(transport: ClientTransportProtocol) {
        self.connectionData = self.onSending()

        transport.negotiate(connection: self, connectionData: self.connectionData, completionHandler: { [unowned self] (response, error) in
            if let error = error {
                self.didReceiveError(error: error)
                self.stopButDoNotCallServer()
                return
            }
            
            defer { self.startTransport() }
            
            guard let response = response else { return }
            
            self.verifyProtocolVersion(versionString: response.protocolVersion)
            
            self.connectionId = response.connectionId
            self.connectionToken = response.connectionToken
            self.disconnectTimeout = response.disconnectTimeout
            
            if let transportTimeout = response.transportConnectTimeout {
                self.transportConnectTimeout += transportTimeout
            }
            
            if let keepAlive = response.keepAliveTimeout {
                self.keepAliveData = KeepAliveData(timeout: keepAlive)
            }
        })
    }

    func startTransport() {
        self.transport?.start(connection: self, connectionData: self.connectionData, completionHandler: { [unowned self] (response, error) in
            if let error = error {
                self.didReceiveError(error: error)
                self.stopButDoNotCallServer()
                return
            }
            
            _ = self.changeState(oldState: .connecting, toState: .connected)
            
            if self.keepAliveData != nil, let transport = self.transport, transport.supportsKeepAlive {
                self.monitor?.start()
            }
            
            self.started?()
            self.delegate?.connectionDidOpen(connection: self)
        })
    }

    open func changeState(oldState: ConnectionState, toState newState: ConnectionState) -> Bool {
        guard self.state == oldState else { /* invalid transition */ return false }
        
        self.state = newState
        self.stateChanged?(self.state)
        self.delegate?.connection(connection: self, didChangeState: oldState, newState: newState)

        return true
    }

    func verifyProtocolVersion(versionString: String) {
        if Version(string: versionString) != self.version {
            NSException.raise(.internalInconsistencyException, format: NSLocalizedString("Incompatible Protocol Version", comment: "internal inconsistency exception"), arguments: getVaList(["nil"]))
        }
    }

    func stopAndCallServer() {
        self.stop(withTimeout: self.defaultAbortTimeout)
    }

    func stopButDoNotCallServer() {
        self.stop(withTimeout: -1.0)
    }

    open func stop() {
        self.stopAndCallServer()
    }

    func stop(withTimeout timeout: Double) {
        guard self.state != .disconnected else { return }

        self.monitor?.stop()
        self.monitor = nil

        self.transport?.abort(connection: self, timeout: timeout, connectionData: self.connectionData)
        self.disconnect()

        self.transport = nil
    }

    open func disconnect() {
        guard self.state != .disconnected else { return }
        
        self.state = .disconnected

        self.monitor?.stop()
        self.monitor = nil

        // clear the state for this connection
        self.connectionId = nil
        self.connectionToken = nil
        self.groupsToken = nil
        self.messageId = nil

        self.didClose()
    }

    // MARK: - Sending Data

    open func onSending() -> String? {
        return nil
    }

    open func send(object: Any, completionHandler: ((Any?, Error?) -> ())?) {
        if self.state == .disconnected {
            let userInfo = [
                NSLocalizedFailureReasonErrorKey: NSExceptionName.internalInconsistencyException.rawValue,
                NSLocalizedDescriptionKey: NSLocalizedString("Start must be called before data can be sent.", comment: "start order exception")
            ]

            let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: self))", code: 0, userInfo: userInfo)
            self.didReceiveError(error: error)
            completionHandler?(nil, error)

            return
        }

        if self.state == .connecting {
            let userInfo = [
                NSLocalizedFailureReasonErrorKey: NSExceptionName.internalInconsistencyException.rawValue,
                NSLocalizedDescriptionKey: NSLocalizedString("The connection has not been established.", comment: "connection not established exception")
            ]

            let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: self))", code: 0, userInfo: userInfo)
            self.didReceiveError(error: error)
            completionHandler?(nil, error)
            return
        }

        self.transport?.send(connection: self, data: object, connectionData: self.connectionData, completionHandler: completionHandler)
    }

    // MARK: - Received Data

    open func didReceiveData(data: Any) {
        self.received?(data)
        self.delegate?.connection(connection: self, didReceiveData: data)
    }

    open func didReceiveError(error: Error) {
        self.error?(error)
        self.delegate?.connection(connection: self, didReceiveError: error)
    }

    open func willReconnect() {
        if let disconnectTimeout = self.disconnectTimeout {
            self.disconnectTimeoutOperation = BlockOperation(block: { [weak self] in self?.stopButDoNotCallServer() })
            self.disconnectTimeoutOperation.perform(#selector(BlockOperation.start), with: nil, afterDelay: disconnectTimeout)
        }

        if let reconnecting = self.reconnecting {
            reconnecting()
        }

        self.delegate?.connectionWillReconnect(connection: self)
    }

    open func didReconnect() {
        NSObject.cancelPreviousPerformRequests(withTarget: self.disconnectTimeoutOperation, selector: #selector(BlockOperation.start), object: nil)
        self.disconnectTimeoutOperation = nil
        
        self.reconnected?()

        self.delegate?.connectionDidReconnect(connection: self)

        self.updateLastKeepAlive()
    }

    open func connectionDidSlow() {
        self.connectionSlow?()
        self.delegate?.connectionDidSlow(connection: self)
    }

    func didClose() {
        self.closed?()
        self.delegate?.connectionDidClose(connection: self)
    }

    // MARK: - Prepare Request

    open func addValue(value: String, forHttpHeaderField field: String) {
        self.headers[field] = value
    }

    open func updateLastKeepAlive() {
        self.keepAliveData?.lastKeepAlive = Date()
    }

    open func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?) -> DataRequest {
        return self.getRequest(url: url, httpMethod: httpMethod, encoding: encoding, parameters: parameters, timeout: 30.0, headers: [:])
    }

    open func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?, timeout: Double) -> DataRequest {
        return self.getRequest(url: url, httpMethod: httpMethod, encoding: encoding, parameters: parameters, timeout: timeout, headers: [:])
    }
    
    open func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?, timeout: Double, headers: HTTPHeaders) -> DataRequest {
        var globalHeaders = self.headers
        globalHeaders["User-Agent"] = self.createUserAgentString(client: "SignalR.Client.iOS")

        for (httpHeader, value) in headers {
            globalHeaders[httpHeader] = value
        }

        var urlRequest = try? URLRequest(url: url.asURL(), method: httpMethod, headers: globalHeaders)
        urlRequest?.timeoutInterval = timeout

        let encodedURLRequest = try? encoding.encode(urlRequest!, with: parameters)
        return sessionManager.request(encodedURLRequest!)
    }

    func createUserAgentString(client: String) -> String {
        if self.assemblyVersion == nil {
            self.assemblyVersion = Version(major: 2, minor: 0)
        }

        return "\(client)/\(self.assemblyVersion!) (\(UIDevice.current.localizedModel) \(UIDevice.current.systemVersion))"
    }

    open func processResponse(response: Data, shouldReconnect: inout Bool, disconnected: inout Bool) {
        self.updateLastKeepAlive()

        shouldReconnect = false
        disconnected = false

        guard let json = try? JSONSerialization.jsonObject(with: response),
            let message = ReceivedMessage(jsonObject: json) else { return }
        
        if message.result != nil {
            self.didReceiveData(data: json)
        }

        if let reconnect = message.shouldReconnect {
            shouldReconnect = reconnect
        }

        if disconnected, let disconnect = message.disconnected {
            disconnected = disconnect
            return
        }

        if let groupsToken = message.groupsToken {
            self.groupsToken = groupsToken
        }

        if let messages = message.messages {
            if let messageId = message.messageId {
                self.messageId = messageId
            }
            
            messages.forEach(self.didReceiveData)
        }
    }
    
    deinit {
        if self.state != .disconnected {
            self.stop()
        }
    }
}
