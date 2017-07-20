//
//  ServerSentEventsTransport.swift
//  SignalR-Swift
//
//  Created by Vladimir Kushelkov on 19/07/2017.
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Alamofire

typealias CompletionHandler = (_ respomce: Any?, _ error: Error) -> ()

public class ServerSentEventsTransport: HttpTransport
{
    var stop = false
    var reconnectDelay: TimeInterval = 2.0
    var serverSentEventsOperationQueue = OperationQueue()
    var connectTimeoutOperation: BlockOperation?
    var completionHandler: CompletionHandler?
    var eventSourceStreamReader: EventSourceStreamReader?
    
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
        self.serverSentEventsOperationQueue.cancelAllOperations()
        super.abort(connection: connection, timeout: timeout, connectionData: connectionData)
    }
    
    override public func lostConnection(connection: ConnectionProtocol) {
        self.serverSentEventsOperationQueue.cancelAllOperations()
    }
    
    // MARK: - SSE Transport
    
    private func open(connection: ConnectionProtocol, connectionData: String?, isReconnecting: Bool)
    {
        var parameters = connection.queryString ?? [:]
        parameters["transport"] = self.name!
        parameters["connectionToken"] = connection.connectionToken ?? ""
        parameters["messageId"] = connection.messageId ?? ""
        parameters["groupsToken"] = connection.groupsToken ?? ""
        parameters["connectionData"] = connectionData ?? ""
        
        let url = isReconnecting ? connection.url.appending("reconnect") : connection.url.appending("connect")
        
        let request = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters, timeout: 240)
        request.validate().response(responseSerializer: <#T##DataResponseSerializerProtocol#>, completionHandler: <#T##(DataResponse<DataResponseSerializerProtocol.SerializedObject>) -> Void#>)
//        request.validate().response(responseSerializer: <#T##DataResponseSerializerProtocol#>, completionHandler: <#T##(DataResponse<DataResponseSerializerProtocol.SerializedObject>) -> Void#>)
//        request.validate().responseData(queue: nil) { [weak self, weak connection] response in
//            guard let strongSelf = self, let strongConnection = connection else { return }
        }
//        var urlRequest = request.request
//        urlRequest?.setValue("Keep-Alive", forHTTPHeaderField: "Connection")

    }
}
