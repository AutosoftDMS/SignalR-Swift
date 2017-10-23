//
//  Message.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

struct ReceivedMessage {

    let result: String?
    let shouldReconnect: Bool?
    let disconnected: Bool?
    let groupsToken: String?
    let messageId: String?
    let messages: [Any]?
    
    init?(jsonObject: Any) {
        
        guard let dict = jsonObject as? [String: Any] else { return nil }
        
        result = dict["I"] as? String
        shouldReconnect = dict["T"] as? Bool
        disconnected = dict["D"] as? Bool
        groupsToken = dict["G"] as? String
        messageId = dict["C"] as? String
        messages = dict["M"] as? [Any]
    }
}
