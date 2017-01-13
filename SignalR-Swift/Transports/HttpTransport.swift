//
//  HttpTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import AlamofireObjectMapper

public class HttpTransport: ClientTransportProtocol {

    public var name: String? {
        return ""
    }

    public var supportsKeepAlive: Bool {
        return false
    }

    var startedAbort: Bool?

    public func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        let url = connection.url.appending("negotiate")

        let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

        let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters.toJSON(), timeout: 30.0)

        encodedRequest.validate().responseObject { (response: DataResponse<NegotiationResponse>) in
            switch response.result {
            case .success(let result):
                if let handler = completionHandler {
                    handler(result, nil)
                }
            case .failure(let error):
                if let handler = completionHandler {
                    handler(nil, error)
                }
            }
        }
    }

    public func start(connection: ConnectionProtocol, connectionData: String, completionHandler: ((Any?, Error?) -> ())?) {

    }

    public func send<T>(connection: ConnectionProtocol, data: T, connectionData: String, completionHandler: ((Any?, Error?) -> ())?) where T: Mappable {
        let url = connection.url.appending("send")

        let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

        let encodedRequest = Alamofire.request(url, method: .get, parameters: parameters.toJSON(), encoding: URLEncoding.default, headers: nil)

        let request = connection.getRequest(url: encodedRequest.request!.url!.absoluteString, httpMethod: .post, encoding: JSONEncoding.default, parameters: ["data": data.toJSON()])

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
        if let abort = self.startedAbort {
            return abort
        }
        return false
    }

    public func lostConnection(connection: ConnectionProtocol) {

    }

    public func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String) {
        if timeout <= 0 {
            return
        }

        if let abort = self.startedAbort, !abort {
            self.startedAbort = true

            let url = connection.url.appending("abort")

            let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

            let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.default, parameters: parameters.toJSON(), timeout: 2.0)

            let request = connection.getRequest(url: encodedRequest.request!.url!.absoluteString, httpMethod: .post, encoding: JSONEncoding.default, parameters: nil)
            request.validate().responseJSON(completionHandler: { (response) in
                switch response.result {
                case .success(_):
                    break
                case .failure(_):
                    self.completeAbort()
                }
            })
        }
    }

    func getConnectionParameters(connection: ConnectionProtocol, connectionData: String) -> ConnectionParameters {
        let parameters = ConnectionParameters()
        parameters.clientProtocol = connection.version.description
        parameters.transport = self.name
        parameters.connectionData = connectionData
        parameters.connectionToken = connection.connectionToken
        parameters.queryString = connection.queryString
        return parameters
    }
}
