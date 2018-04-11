//
//  HttpTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Alamofire

public class HttpTransport: ClientTransportProtocol {

    public var name: String? {
        return ""
    }

    public var supportsKeepAlive: Bool {
        return false
    }

    var startedAbort: Bool = false

    public func negotiate(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        let url = connection.url.appending("negotiate")

        let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

        let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters, timeout: 30.0)

        encodedRequest.validate().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(let result):
                if let json = result as? [String: Any] {
                    completionHandler?(NegotiationResponse(jsonObject: json), nil)
                }
                else {
                    completionHandler?(nil, AFError.responseSerializationFailed(reason: .inputDataNil))
                }
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }

    public func start(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {

    }

    public func send(connection: ConnectionProtocol, data: Any, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        let url = connection.url.appending("send")

        let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)
        
        var encodedRequestURL = url
        do {
            let originalRequest = try URLRequest(url: url, method: .get, headers: nil)
            encodedRequestURL = try URLEncoding.queryString.encode(originalRequest, with: parameters).url!.absoluteString
        } catch {
        }
        
        var requestParams = [String: Any]()

        if let dataString = data as? String {
            requestParams["data"] = dataString
        } else if let dataDict = data as? [String: Any] {
            requestParams = dataDict
        }
        
        let request = connection.getRequest(url: encodedRequestURL, httpMethod: .post, encoding: URLEncoding.httpBody, parameters: requestParams)
        request.validate().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(let result):
                connection.didReceiveData(data: result)

                if let handler = completionHandler {
                    handler(result, nil)
                }
            case .failure(let error):
                connection.didReceiveError(error: error)

                if let handler = completionHandler {
                    handler(nil, error)
                }
            }
        }
    }

    func completeAbort() {
        self.startedAbort = true
    }

    func tryCompleteAbort() -> Bool {
        return startedAbort
    }

    public func lostConnection(connection: ConnectionProtocol) {

    }

    public func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String?) {
        guard timeout > 0, !self.startedAbort else { return }
       
        self.startedAbort = true

        let url = connection.url.appending("abort")

        let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

        let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters, timeout: 2.0)

        let request = connection.getRequest(url: encodedRequest.request!.url!.absoluteString, httpMethod: .post, encoding: URLEncoding.httpBody, parameters: nil)
        request.validate().response { response in
            if response.error != nil {
                self.completeAbort()
            }
        }
    }
    
    func getConnectionParameters(connection: ConnectionProtocol, connectionData: String?) -> [String: Any] {
        var parameters: [String: Any] = [
            "clientProtocol": connection.version.description,
            "transport": self.name ?? "",
            "connectionData": connectionData ?? "",
            "connectionToken": connection.connectionToken ?? "",
            ]
        
        if let queryString = connection.queryString {
            for (key, value) in queryString {
                parameters[key] = value
            }
        }
        
        return parameters
    }
}
