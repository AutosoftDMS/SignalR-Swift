//
//  Connection.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import UIKit

class Connection {
    var defaultAbortTimeout = 0
    var assemblyVersion: Version?
    var disconnectTimeout = 0
    var disconnectTimeoutOperation: BlockOperation!

    var state = ConnectionState.disconnected
    var url: String!

    var items = [String : AnyObject]()
    let queryString: [String: AnyObject]!

    var connectionData: String!




    init(url: String, queryString: [String: AnyObject]) {
        self.url = url.hasSuffix("/") ? url : url.appending("/")
        self.queryString = queryString
    }
}
