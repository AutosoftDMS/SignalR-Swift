//
//  HubProxy.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

public class HubProxy: HubProxyProtocol {

    public var state = [String: Any]()

    private weak var connection: HubConnectionProtocol?
    private var hubName: String?
    private var subscriptions = [String: Subscription]()

    // MARK: - Init

    public init(connection: HubConnectionProtocol, hubName: String) {
        self.connection = connection
        self.hubName = hubName
    }

    // MARK: - Subscribe

    public func on(eventName: String?, handler: @escaping Subscription) -> Subscription? {
        guard eventName != nil && !eventName!.isEmpty else {
            NSException.raise(.invalidArgumentException, format: NSLocalizedString("Argument eventName is null", comment: "null event name exception"), arguments: getVaList(["nil"]))
            return nil
        }
        
        return self.subscriptions[eventName!] ?? self.subscriptions.updateValue(handler, forKey: eventName!)
    }

    public func invokeEvent(eventName: String, withArgs args: [Any]) {
        if let subscription = self.subscriptions[eventName] {
            subscription(args)
        }
    }

    // MARK: - Publish

    public func invoke(method: String?, withArgs args: [Any]) {
        self.invoke(method: method, withArgs: args, completionHandler: nil)
    }

    public func invoke(method: String?, withArgs args: [Any], completionHandler: ((Any?, Error?) -> ())?) {
        guard method != nil && !method!.isEmpty else {
            NSException.raise(.invalidArgumentException, format: NSLocalizedString("Argument method is null", comment: "null event name exception"), arguments: getVaList(["nil"]))
            return
        }
        
        guard let connection = self.connection else {
            return
        }

        let callbackId = connection.registerCallback { (result) in
            if let hubResult = result {
                if let state = hubResult.state {
                    for key in state.keys {
                        self.state[key] = state[key]
                    }
                }

                if let subResult = hubResult.result {
                    if let handler = completionHandler {
                        handler(subResult, nil)
                    }
                } else if let handler = completionHandler {
                    handler(nil, nil)
                }
            }
        }

        let hubData = HubInvocation(callbackId: callbackId,
                                    hub: self.hubName!,
                                    method: method!,
                                    args: args,
                                    state: self.state)
        
        connection.send(object: hubData.toJSONString()!, completionHandler: completionHandler)
    }
}
