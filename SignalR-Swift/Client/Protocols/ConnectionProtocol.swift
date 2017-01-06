//
//  ConnectionProtocol.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

protocol ConnectionProtocol {
    var version: Version { get set }
    var transportConnectTimeout: Int { get set }
    var keepAliveData: KeepAliveData { get set }
    var messageId: String { get set }
    var groupsToken: String { get set }
    var items: [String: AnyObject] { get set }
    var connectionId: String { get set }
    var connectionToken: String { get set }
    var url: String { get }
    var queryString: [String: AnyObject] { get }
    var state: ConnectionState { get }
}
