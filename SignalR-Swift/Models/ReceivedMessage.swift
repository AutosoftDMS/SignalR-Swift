//
//  Message.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper

class ReceivedMessage: Mappable {

    var result: String?
    var shouldReconnect: Bool?
    var disconnected: Bool?

    var groupsToken: String?
    var messageId: String?
    var messages: [Any]?

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        result <- map["I"]
        shouldReconnect <- map["T"]
        disconnected <- map["D"]

        groupsToken <- map["G"]
        messageId <- map["C"]
        messages <- map["M"]
    }
}
