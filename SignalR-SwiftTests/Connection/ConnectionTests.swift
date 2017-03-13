//
//  ConnectionTests.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Mockit
import XCTest
@testable import SignalRSwift

class ConnectionTests: QuickSpec {
    var connection: Connection!
    var mockClientTransport: MockClientTransport!

    override func spec() {
        beforeEach {
            self.mockClientTransport = MockClientTransport(testCase: self)
            self.connection = Connection(withUrl: "http://localhost:0000")
        }

        it("should cause a closed event when transport error occurs") {
            self.connection.start(transport: self.mockClientTransport)
            self.expectation(description: "gets closed when transport errors out")
            
            self.waitForExpectations(timeout: 5.0, handler: { error in
                if let theError = error {
                    print("Sub-Timeout Error: \(theError)")
                }
            })
        }
    }
}
