//
//  HubResult.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import ObjectMapper

private let kId = "I"
private let kResult = "R"
private let kHubException = "H"
private let kError = "E"
private let kErrorData = "D"
private let kState = "S"

public class HubResult: Mappable {

    var id: String?

    var result: Any?
    var hubException = false
    var error: String?

    var errorData: Any?

    var state: [String: Any]?

    init() {
        
    }

    required public init?(map: Map) {

    }

    public func mapping(map: Map) {
        id <- map[kId]
        result <- map[kResult]
        hubException <- map[kHubException]
        error <- map[kError]
        errorData <- map[kErrorData]
        state <- map[kState]
    }
}
