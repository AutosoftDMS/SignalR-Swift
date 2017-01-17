//
//  Dictionary+Json.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral {
    func toJSONString() -> String? {
        do {
            return String(data: try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted), encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }

        return nil
    }
}
