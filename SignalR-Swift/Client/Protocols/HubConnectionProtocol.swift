//
//  HubConnectionProtocol.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

typealias HubConnectionHubResultClosure = (HubResult?) -> ()

protocol HubConnectionProtocol: ConnectionProtocol {
    func registerCallback(callback: @escaping HubConnectionHubResultClosure) -> String
    func removeCallback(callbackId: String)
}
