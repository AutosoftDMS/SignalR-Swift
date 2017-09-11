//
//  HubRegistrationData.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper

private let kName = "Name"

struct HubRegistrationData: Mappable {
    private(set) var name = ""

    init(name: String) {
        self.name = name
    }

    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        name <- map[kName]
    }
}
