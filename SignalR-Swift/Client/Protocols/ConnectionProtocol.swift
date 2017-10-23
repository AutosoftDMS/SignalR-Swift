//
//  ConnectionProtocol.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

public protocol ConnectionProtocol: class {
    var version: Version { get set }
    var transportConnectTimeout: Double { get set }
    var keepAliveData: KeepAliveData? { get set }
    var messageId: String? { get set }
    var groupsToken: String? { get set }
    var items: [String: Any] { get set }
    var connectionId: String? { get set }
    var connectionToken: String? { get set }
    var url: String { get }
    var queryString: [String: String]? { get }
    var state: ConnectionState { get }
    var transport: ClientTransportProtocol? { get }
    var headers: HTTPHeaders { get set }
    var sessionManager: SessionManager { get }
    var webSocketAllowsSelfSignedSSL: Bool { get set }

    func onSending() -> String?

    func changeState(oldState: ConnectionState, toState newState: ConnectionState) -> Bool
    func stop()
    func disconnect()

    func send(object: Any, completionHandler: ((Any?, Error?) -> ())?)

    func didReceiveData(data: Any)
    func didReceiveError(error: Error)
    func willReconnect()
    func didReconnect()
    func connectionDidSlow()

    func updateLastKeepAlive()

    func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?) -> DataRequest
    func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?, timeout: Double) -> DataRequest
    func getRequest(url: URLConvertible, httpMethod: HTTPMethod, encoding: ParameterEncoding, parameters: Parameters?, timeout: Double, headers: HTTPHeaders) -> DataRequest
    func processResponse(response: Data, shouldReconnect: inout Bool, disconnected: inout Bool)
}
