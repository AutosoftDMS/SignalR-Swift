//
//  AutoTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper

public class AutoTransport: HttpTransport {
    var transports = [ClientTransportProtocol]()
    var transport: ClientTransportProtocol?

    override convenience init() {
        let transports = [
            WebSocketTransport(),

            //TODO: implement server sent events. it was decided that for now web sockets and long polling should be enough

            LongPollingTransport()
        ]

        self.init(withTransports: transports)
    }

    init(withTransports transports: [ClientTransportProtocol]) {
        self.transports = transports
    }

    // MARK: - Client Transport Protocol

    override public var name: String? {
        if self.transport == nil {
            return nil
        }

        return self.transport?.name
    }

    override public var supportsKeepAlive: Bool {
        if let transport = self.transport {
            return transport.supportsKeepAlive
        }

        return false
    }

    override public func negotiate(connection: ConnectionProtocol, connectionData: String, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        super.negotiate(connection: connection, connectionData: connectionData) { [unowned self] (response, error) in

            if error == nil {
                if let tryWebSockets = response?.tryWebSockets, !tryWebSockets {
                    if let invalidIndex = self.transports.index(where: { (element) -> Bool in
                        element.name == "webSockets" 
                    }) {
                        self.transports.remove(at: invalidIndex)
                    }
                }
            }

            if let handler = completionHandler {
                handler(response, error)
            }
        }
    }

    override public func start(connection: ConnectionProtocol, connectionData: String, completionHandler: ((Any?, Error?) -> ())?) {
        self.start(connection: connection, connectionData: connectionData, transportIndex: 0, completionHandler: completionHandler)
    }

    func start(connection: ConnectionProtocol, connectionData: String, transportIndex index: Int, completionHandler: ((String?, Error?) -> ())?) {
        let transport = self.transports[index]
        transport.start(connection: connection, connectionData: connectionData) { [unowned self] (response, error) in

            if error != nil {
                let nextIndex = index + 1

                if nextIndex < self.transports.count {
                    self.start(connection: connection, connectionData: connectionData, transportIndex: nextIndex, completionHandler: completionHandler)
                } else {
                    let userInfo = [
                        NSLocalizedFailureReasonErrorKey: NSExceptionName.internalInconsistencyException.rawValue,
                        NSLocalizedDescriptionKey: NSLocalizedString("No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization.", comment: "no transport initialized")
                    ]

                    let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: self))", code: 0, userInfo: userInfo)

                    if let handler = completionHandler {
                        handler(nil, error)
                    }
                }
            } else {
                self.transport = transport

                if let handler = completionHandler {
                    handler(nil, nil)
                }
            }
        }
    }

    override public func send<T>(connection: ConnectionProtocol, data: T, connectionData: String, completionHandler: ((Any?, Error?) -> ())?) where T : Mappable {
        self.transport?.send(connection: connection, data: data, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func lostConnection(connection: ConnectionProtocol) {
        self.transport?.lostConnection(connection: connection)
    }
}
