//
//  ConnectionParameters.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper

class ConnectionParameters: Mappable {
    var clientProtocol: Version?
    var connectionData: String?
    var connectionToken: String?
    var transport: String?
    var queryString: [String: String]?

    init() {
        
    }

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        clientProtocol <- map["clientProtocol"]
        transport <- map["transport"]
        connectionData <- map["connectionData"]
        connectionToken <- map["connectionToken"]
        queryString <- map["queryString"]
    }
}
