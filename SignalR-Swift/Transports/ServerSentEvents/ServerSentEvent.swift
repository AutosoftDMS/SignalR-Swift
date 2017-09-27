//
//  ServerSentEvent.swift
//  SignalR-Swift
//
//  Created by Vladimir Kushelkov on 21/07/2017.
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

struct ServerSentEvent {
    
    enum Event: String {
        case data
        case id
    }
    
    let event: Event
    let identifier: String?
    let data: String?
    let retry: String?
    let userInfo: String?
    
    static private func event(withFields fields: [String: String]) -> ServerSentEvent {
        return ServerSentEvent(event: Event(rawValue: fields["event"]!)!,
                               identifier: fields["id"],
                               data: fields["data"],
                               retry: fields["retry"],
                               userInfo: nil)
    }
    
    static func tryParse(line: String) -> ServerSentEvent? {
        if line.hasPrefix("data:") {
            let data = line["data:".endIndex..<line.endIndex].trimmingCharacters(in: .whitespaces)
            return ServerSentEvent.event(withFields: ["event": Event.data.rawValue, "data": data])
        }
        
        if line.hasPrefix("id:") {
            let data = line["id:".endIndex..<line.endIndex].trimmingCharacters(in: .whitespaces)
            return ServerSentEvent.event(withFields: ["event": Event.id.rawValue, "id": data])
        }
        
        return nil
    }
}
