//
//  HubResult.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

private let kId = "I"
private let kResult = "R"
private let kHubException = "H"
private let kError = "E"
private let kErrorData = "D"
private let kState = "S"

public struct HubResult {
    let id: String?
    let result: Any?
    let hubException: Bool
    let error: String?
    let errorData: Any?
    let state: [String: Any]?
    
    init(id: String? = nil, result: Any? = nil, hubException: Bool = false, error: String? = nil, errorData: Any? = nil, state: [String: Any]? = nil) {
        self.id = id
        self.result = result
        self.hubException = hubException
        self.error = error
        self.errorData = errorData
        self.state = state
    }
    
    init(jsonObject dict: [String: Any]) {
        id = dict[kId] as? String
        result = dict[kResult]
        hubException = dict[kHubException] as? Bool ?? false
        error = dict[kError] as? String
        errorData = dict[kErrorData]
        state = dict[kState] as? [String: Any]
    }
}
