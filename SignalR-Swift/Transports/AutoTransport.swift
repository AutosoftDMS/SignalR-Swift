//
//  AutoTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

public class AutoTransport: HttpTransport {
    var transports = [ClientTransportProtocol]()
    var transport: ClientTransportProtocol?

    override convenience init() {
        let transports = [
            WebSocketTransport(),
            ServerSentEventsTransport(),
            LongPollingTransport()
        ]

        self.init(withTransports: transports)
    }

    init(withTransports transports: [ClientTransportProtocol]) {
        self.transports = transports
    }

    // MARK: - Client Transport Protocol

    override public var name: String? {
        return self.transport?.name
    }

    override public var supportsKeepAlive: Bool {
        return self.transport?.supportsKeepAlive ?? false
    }

    override public func negotiate(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((NegotiationResponse?, Error?) -> ())?) {
        super.negotiate(connection: connection, connectionData: connectionData) { [weak self] (response, error) in
            guard let strongRef = self else { return }
            
            if error == nil,
                let tryWebSockets = response?.tryWebSockets, !tryWebSockets,
                let invalidIndex = strongRef.transports.index(where: { $0.name == "webSockets" }) {
                strongRef.transports.remove(at: invalidIndex)
            }
            
            completionHandler?(response, error)
        }
    }

    override public func start(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        self.start(connection: connection, connectionData: connectionData, transportIndex: 0, completionHandler: completionHandler)
    }

    func start(connection: ConnectionProtocol, connectionData: String?, transportIndex index: Int, completionHandler: ((String?, Error?) -> ())?) {
        let transport = self.transports[index]
        transport.start(connection: connection, connectionData: connectionData) { [weak self] (response, error) in
            guard let strongRef = self else { return }

            if error != nil {
                let nextIndex = index + 1

                if nextIndex < strongRef.transports.count {
                    strongRef.start(connection: connection, connectionData: connectionData, transportIndex: nextIndex, completionHandler: completionHandler)
                } else {
                    let userInfo = [
                        NSLocalizedFailureReasonErrorKey: NSExceptionName.internalInconsistencyException.rawValue,
                        NSLocalizedDescriptionKey: NSLocalizedString("No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization.", comment: "no transport initialized")
                    ]

                    let error = NSError(domain: "com.autosoftdms.SignalR-Swift.\(type(of: self))", code: 0, userInfo: userInfo)

                    completionHandler?(nil, error)
                }
            } else {
                strongRef.transport = transport

                completionHandler?(nil, nil)
            }
        }
    }

    override public func send(connection: ConnectionProtocol, data: Any, connectionData: String?, completionHandler: ((Any?, Error?) -> ())?) {
        self.transport?.send(connection: connection, data: data, connectionData: connectionData, completionHandler: completionHandler)
    }

    override public func lostConnection(connection: ConnectionProtocol) {
        self.transport?.lostConnection(connection: connection)
    }

    public override func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String?) {
        self.transport?.abort(connection: connection, timeout: timeout, connectionData: connectionData)
    }
}
