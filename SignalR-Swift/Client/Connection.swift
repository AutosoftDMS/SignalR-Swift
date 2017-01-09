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

class Connection: ConnectionProtocol {
    var defaultAbortTimeout = 0.0
    var assemblyVersion: Version?
    var disconnectTimeout = 0.0
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
    var transportConnectTimeout: Double

    static func connection(withUrl url: String) -> Connection {
        return Connection(withUrl: url)
    }

    static func connection(withUrl url: String, queryString: [String: String]?) -> Connection {
        return Connection(withUrl: url, queryString: queryString)
    }

    convenience init(withUrl url: String) {
        self.init(withUrl: url, queryString: nil)
    }

    init(withUrl url: String, queryString: [String: String]?) {
        self.url = url.hasSuffix("/") ? url : url.appending("/")
        self.queryString = queryString

        self.state = .disconnected
        self.defaultAbortTimeout = 30
        self.transportConnectTimeout = 0
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

    // MARK: - Connection management

    func start() {

    }

    func start(transport: ClientTransportProtocol) {
        // change state

        self.monitor = HeartbeatMonitor(withConnection: self)
        self.transport = transport
    }

    func negotiate(transport: ClientTransportProtocol) {
        self.connectionData = self.onSending()

        transport.negotiate(connection: self, connectionData: self.connectionData, completionHandler: { (response, error) in
            if error == nil {

            }
        })
    }

    func startTransport() {
//        self.transport?.start(connection: self, connectionData: self.connectionData, completionHandler: { (response, error) in
//            if error == nil {
//
//            }
//        })
    }

    func changeState(oldState: ConnectionState, toState newState: ConnectionState) -> Bool {
        if self.state == oldState {
            self.state = newState

            // stateChanged

            //delegate

            return true
        }

        return false
    }

    func verifyProtocolVersion(versionString: String?) {
        var version: Version?

        if versionString == nil || versionString!.isEmpty || Version.parse(input: versionString, forVersion: &version) || version == self.version {
            NSException.raise(.internalInconsistencyException, format: NSLocalizedString("Incompatible Protocol Version", comment: "internal inconsistency exception"), arguments: getVaList(["nil"]))
        }
    }

    func stopAndCallServer() {

    }

    func stopButDoNotCallServer() {

    }

    func stop() {

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

//            self.didClose()
        }
    }

    // MARK: - Sending Data

    func onSending() -> String? {
        return nil
    }

    func send(object: Any, completionHandler: ((Any, Error) -> ())) {
        if self.state == .disconnected {

        }

        if self.state == .connecting {
            
        }
    }

    // MARK: - Received Data

    func didReceiveData<T>(data: T) where T: Mappable {
        // received
    }

    func didReceiveError(error: Error) {
        // error

        // delegate
    }

    func willReconnect() {
        self.disconnectTimeoutOperation = BlockOperation(block: { [unowned self] in
            self.stopButDoNotCallServer()
        })

//        self.disconnectTimeoutOperation.perform(#selector(Connection.start), with: nil, afterDelay: self.disconnectTimeout)

//        if self.reconnecting != nil {
//            self.reconnecting()
//        }

        // delegate
    }

    func didReconnect() {
        NSObject.cancelPreviousPerformRequests(withTarget: self.disconnectTimeoutOperation, selector: #selector(BlockOperation.start), object: nil)

        self.disconnectTimeoutOperation = nil

        // if self.reconnected != nil {
        // self.reconnected()
        // }

        // delegate

        self.updateLastKeepAlive()
    }

    func connectionDidSlow() {
//        if self.connectionSlow != nil {
//            self.connectionSlow()
//        }

        // delegate
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
        self.headers["User-Agent"] = self.createUserAgentString(client: "SignalR.Client.iOS")
        return Alamofire.request(url, method: httpMethod, parameters: parameters, encoding: encoding, headers: self.headers)
    }

    func createUserAgentString(client: String) -> String {
        if self.assemblyVersion == nil {
            self.assemblyVersion = Version(major: 2, minor: 0, build: 0, revision: 0)
        }

        return "\(client)/\(self.assemblyVersion) (\(UIDevice.current.localizedModel) \(UIDevice.current.systemVersion))"
    }
}
