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

class HubRegistrationData: Mappable {
    var name = ""

    init() {

    }

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        name <- map[kName]
    }
}
