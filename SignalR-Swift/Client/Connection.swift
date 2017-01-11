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
import ObjectMapper

typealias ConnectionStartedClosure = (() -> ())
typealias ConnectionReceivedClosure = ((Any) -> ())
typealias ConnectionErrorClosure = ((Error) -> ())
typealias ConnectionClosedClosure = (() -> ())
typealias ConnectionReconnectingClosure = (() -> ())
typealias ConnectionReconnectedClosure = (() -> ())
typealias ConnectionStateChangedClosure = ((ConnectionState) -> ())
typealias ConnectionConnectionSlowClosure = (() -> ())

class Connection: ConnectionProtocol {
    var defaultAbortTimeout = 30.0
    var assemblyVersion: Version?
    var disconnectTimeout: Double?
    var disconnectTimeoutOperation: BlockOperation!

    var state = ConnectionState.disconnected
    var url: String

    var items = [String : Any]()
    let queryString: [String: String]?

    var connectionData: String!
    var monitor: HeartbeatMonitor?

    internal var version = Version(major: 1, minor: 3)

    var connectionId: String?
    var connectionToken: String?
    var groupsToken: String?
    var messageId: String?

    var headers = HTTPHeaders()
    var keepAliveData: KeepAliveData?

    var transport: ClientTransportProtocol?
    var transportConnectTimeout = 0.0

    var started: ConnectionStartedClosure?
    var received: ConnectionReceivedClosure?
    var error: ConnectionErrorClosure?
    var closed: ConnectionClosedClosure?
    var reconnecting: ConnectionReconnectingClosure?
    var reconnected: ConnectionReconnectedClosure?
    var stateChanged: ConnectionStateChangedClosure?
    var connectionSlow: ConnectionConnectionSlowClosure?

    weak var delegate: ConnectionDelegate?

    static func connection(withUrl url: String) -> Connection {
        return Connection(withUrl: url)
    }

    static func connection(withUrl url: String, queryString: [String: String]?) -> Connection {
        return Connection(withUrl: url, queryString: queryString)
    }

    static func ensureReconnecting(connection: ConnectionProtocol?) -> Bool {
        if connection == nil {
            return false
        }

        if connection!.changeState(oldState: .connected, toState: .reconnecting) {
            connection!.willReconnect()
        }

        return connection!.state == .reconnecting
    }

    init(withUrl url: String) {
        self.url = url.hasSuffix("/") ? url : url.appending("/")
        self.queryString = nil
    }

    init(withUrl url: String, queryString: [String: String]?) {
        self.url = url.hasSuffix("/") ? url : url.appending("/")
        self.queryString = queryString
    }

    // MARK: - Connection management

    func start() {
        self.start(transport: AutoTransport())
    }

    func start(transport: ClientTransportProtocol) {
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
            if error == nil {
                self.verifyProtocolVersion(versionString: response?.protocolVersion)

                self.connectionId = response?.connectionId
                self.connectionToken = response?.connectionToken
                self.disconnectTimeout = response?.disconnectTimeout

                if let transportTimeout = response?.transportConnectTimeout {
                    self.transportConnectTimeout += transportTimeout
                }

                if let keepAlive = response?.keepAliveTimeout {
                    self.keepAliveData = KeepAliveData(timeout: keepAlive)
                }

                self.startTransport()
            } else if let error = error {
                self.didReceiveError(error: error)
                self.stopButDoNotCallServer()
            }
        })
    }

    func startTransport() {
        self.transport?.start(connection: self, connectionData: self.connectionData, completionHandler: { [unowned self] (response, error) in
            if error == nil {
                _ = self.changeState(oldState: .connecting, toState: .connected)

                if let _ = self.keepAliveData, let transport = self.transport, transport.supportsKeepAlive {
                    self.monitor?.start()
                }

                if let started = self.started {
                    started()
                }

                self.delegate?.connectionDidOpen(connection: self)
            } else if let error = error {
                self.didReceiveError(error: error)
                self.stopButDoNotCallServer()
            }
        })
    }

    func changeState(oldState: ConnectionState, toState newState: ConnectionState) -> Bool {
        if self.state == oldState {
            self.state = newState

            if let stateChanged = self.stateChanged {
                stateChanged(self.state)
            }

            self.delegate?.connection(connection: self, didChangeState: oldState, newState: newState)

            return true
        }

        // invalid transition
        return false
    }

    func verifyProtocolVersion(versionString: String?) {
        var version: Version?

        if versionString == nil || versionString!.isEmpty || Version.parse(input: versionString, forVersion: &version) || version == self.version {
            NSException.raise(.internalInconsistencyException, format: NSLocalizedString("Incompatible Protocol Version", comment: "internal inconsistency exception"), arguments: getVaList(["nil"]))
        }
    }

    func stopAndCallServer() {
        self.stop(withTimeout: self.defaultAbortTimeout)
    }

    func stopButDoNotCallServer() {
        self.stop(withTimeout: -1.0)
    }

    func stop() {
        self.stopAndCallServer()
    }

    func stop(withTimeout timeout: Double) {
        if self.state != .disconnected {

            self.monitor?.stop()
            self.monitor = nil

            self.transport?.abort(connection: self, timeout: timeout, connectionData: self.connectionData)
            self.disconnect()

            self.transport = nil
        }
    }

    func disconnect() {
        if self.state != .disconnected {
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
    }

    // MARK: - Sending Data

    func onSending() -> String? {
        return nil
    }

    func send<T>(object: T, completionHandler: ((Any?, Error?) -> ())?) where T: Mappable {
        if self.state == .disconnected {
            let userInfo = [
                NSLocalizedFailureReasonErrorKey: NSExceptionName.internalInconsistencyException.rawValue,
                NSLocalizedDescriptionKey: NSLocalizedString("Start must be called before data can be sent.", comment: "start order exception")
            ]

            let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: self))", code: 0, userInfo: userInfo)
            self.didReceiveError(error: error)
            if let handler = completionHandler {
                handler(nil, error)
            }

            return
        }

        if self.state == .connecting {
            let userInfo = [
                NSLocalizedFailureReasonErrorKey: NSExceptionName.internalInconsistencyException.rawValue,
                NSLocalizedDescriptionKey: NSLocalizedString("The connection has not been established.", comment: "connection not established exception")
            ]

            let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: self))", code: 0, userInfo: userInfo)
            self.didReceiveError(error: error)
            if let handler = completionHandler {
                handler(nil, error)
            }
            return
        }

        self.transport?.send(connection: self, data: object, connectionData: self.connectionData, completionHandler: completionHandler)
    }

    // MARK: - Received Data

    func didReceiveData(data: Any) {
        if let received = self.received {
            received(data)
        }

        self.delegate?.connection(connection: self, didReceiveData: data)
    }

    func didReceiveError(error: Error) {
        if let errorClosure = self.error {
            errorClosure(error)
        }

        self.delegate?.connection(connection: self, didReceiveError: error)
    }

    func willReconnect() {
        self.disconnectTimeoutOperation = BlockOperation(block: { [unowned self] in
            self.stopButDoNotCallServer()
        })

        if let disconnectTimeout = self.disconnectTimeout {
            self.disconnectTimeoutOperation.perform(#selector(BlockOperation.start), with: nil, afterDelay: disconnectTimeout)
        }

        if let reconnecting = self.reconnecting {
            reconnecting()
        }

        self.delegate?.connectionWillReconnect(connection: self)
    }

    func didReconnect() {
        NSObject.cancelPreviousPerformRequests(withTarget: self.disconnectTimeoutOperation, selector: #selector(BlockOperation.start), object: nil)

        self.disconnectTimeoutOperation = nil

        if let reconnected = self.reconnected {
            reconnected()
        }

        self.delegate?.connectionDidReconnect(connection: self)

        self.updateLastKeepAlive()
    }

    func connectionDidSlow() {
        if let connectionSlow = self.connectionSlow {
            connectionSlow()
        }

        self.delegate?.connectionDidSlow(connection: self)
    }

    func didClose() {
        if let closed = self.closed {
            closed()
        }

        self.delegate?.connectionDidClose(connection: self)
    }

    // MARK: - Prepare Request

    func addValue(value: String, forHttpHeaderField field: String) {
        self.headers[field] = value
    }

    func updateLastKeepAlive() {
        if let keepAlive = self.keepAliveData {
            keepAlive.lastKeepAlive = Date()
        }
    }

    func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?) -> DataRequest {
        return self.getRequest(url: url, httpMethod: httpMethod, encoding: encoding, parameters: parameters, timeout: 30.0)
    }

    func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?, timeout: Double) -> DataRequest {
        self.headers["User-Agent"] = self.createUserAgentString(client: "SignalR.Client.iOS")
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        let manager = Alamofire.SessionManager(configuration: configuration)
        return manager.request(url, method: httpMethod, parameters: parameters, encoding: encoding, headers: self.headers)
    }

    func createUserAgentString(client: String) -> String {
        if self.assemblyVersion == nil {
            self.assemblyVersion = Version(major: 2, minor: 0, build: 0, revision: 0)
        }

        return "\(client)/\(self.assemblyVersion) (\(UIDevice.current.localizedModel) \(UIDevice.current.systemVersion))"
    }

    func processResponse(response: Any?, shouldReconnect: inout Bool, disconnected: inout Bool) {
        self.updateLastKeepAlive()

        shouldReconnect = false
        disconnected = false

        if response == nil {
            return
        }

        if let responseDict = response as? [String: Any], let message = ReceivedMessage(JSON: responseDict) {
            if let resultMessage = message.result {
                self.didReceiveData(data: resultMessage)
            }

            if let disconnected = message.disconnected, disconnected {
                return
            }

            if let groupsToken = message.groupsToken {
                self.groupsToken = groupsToken
            }

            if let messages = message.messages {
                if let messageId = message.messageId {
                    self.messageId = messageId
                }

                for message in messages {
                    self.didReceiveData(data: message)
                }
            }
        }
    }
}
