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

class HttpTransport<TResponse>: ClientTransportProtocol where TResponse: Mappable {

    var name: String! {
        return ""
    }

    var supportsKeepAlive: Bool {
        return false
    }

    var startedAbort = false

    func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        let url = connection.url.appending("negotiate")

        let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

        let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.queryString, parameters: parameters.toJSON())

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

    func start(connection: ConnectionProtocol, connectionData: String, completionHandler: ((Any?, Error?) -> ())?) {

    }

    func send<T>(connection: ConnectionProtocol, data: T, connectionData: String, completionHandler: ((T?, Error?) -> ())?) where T: Mappable {
        let url = connection.url.appending("send")

        let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

        let encodedRequest = Alamofire.request(url, method: .get, parameters: parameters.toJSON(), encoding: URLEncoding.queryString, headers: nil)

        let request = connection.getRequest(url: encodedRequest.request!.url!.absoluteString, httpMethod: .post, encoding: JSONEncoding.default, parameters: ["data": data.toJSON()])

        request.validate().responseObject { (response: DataResponse<T>) in
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
        return self.startedAbort
    }

    func lostConnection(connection: ConnectionProtocol) {

    }

    func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String) {
        if timeout <= 0 {
            return
        }

        if !self.startedAbort {
            self.startedAbort = true

            let url = connection.url.appending("abort")

            let parameters = self.getConnectionParameters(connection: connection, connectionData: connectionData)

            let encodedRequest = connection.getRequest(url: url, httpMethod: .get, encoding: URLEncoding.queryString, parameters: parameters.toJSON())

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
        parameters.clientProtocol = connection.version
        parameters.transport = self.name
        parameters.connectionData = connectionData
        parameters.connectionToken = connection.connectionToken
        parameters.queryString = connection.queryString
        return parameters
    }

    func processResponse<T>(connection: inout ConnectionProtocol, response: T?, shouldReconnect: inout Bool, disconnected: inout Bool) where T: Mappable {
        connection.updateLastKeepAlive()

        shouldReconnect = false
        disconnected = false

        if response == nil {
            return
        }

        if let result = response?.toJSON() {
            if let iResult = result["I"] as? T {
                connection.didReceiveData(data: iResult)
            }

            if let tResult = result["T"] as? Bool {
                shouldReconnect = tResult
            }

            if let dResult = result["D"] as? Bool {
                disconnected = dResult
            }

            if disconnected {
                return
            }

            if let groupsToken = result["G"] as? String {
                connection.groupsToken = groupsToken
            }

            if let messages = result["M"] as? [T] {
                if let messageId = result["C"] as? String {
                    connection.messageId = messageId
                }

                for message in messages {
                    connection.didReceiveData(data: message)
                }

            }
        }


    }
}
