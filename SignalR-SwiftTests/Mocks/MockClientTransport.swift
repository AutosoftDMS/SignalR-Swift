//
//  MockClientTransport.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Mockit
import XCTest
@testable import SignalRSwift

class MockClientTransport: ClientTransportProtocol, Mock {
    public var callHandler: CallHandler

    init(testCase: XCTestCase) {
        self.callHandler = CallHandlerImpl(withTestCase: testCase)
    }

    func instanceType() -> MockClientTransport {
        return self
    }

    var name: String? {
        return self.callHandler.accept("", ofFunction: #function, atFile: #file, inLine: #line, withArgs: self.name) as! String?
    }

    var supportsKeepAlive: Bool {
        return self.callHandler.accept(true, ofFunction: #function, atFile: #file, inLine: #line, withArgs: self.supportsKeepAlive) as! Bool
    }

    func negotiate(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((_ response: NegotiationResponse?, _ error: Error?) -> ())?) {
        self.callHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: connection, connectionData, completionHandler)
    }

    func start(connection: ConnectionProtocol, connectionData: String?, completionHandler: ((_ response: Any?, _ error: Error?) -> ())?) {
        self.callHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: connection, connectionData, completionHandler)
    }

    func send(connection: ConnectionProtocol, data: Any, connectionData: String?, completionHandler: ((_ response: Any?, _ error: Error?) -> ())?) {
        self.callHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: connection, connectionData, completionHandler)
    }

    func abort(connection: ConnectionProtocol, timeout: Double, connectionData: String?) {
        self.callHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: connection, timeout, connectionData)
    }

    func lostConnection(connection: ConnectionProtocol) {
        self.callHandler.accept(nil, ofFunction: #function, atFile: #file, inLine: #line, withArgs: connection)
    }
}
