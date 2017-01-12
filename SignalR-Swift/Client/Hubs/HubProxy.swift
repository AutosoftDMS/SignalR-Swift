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

    private var connection: HubConnectionProtocol!
    private var hubName: String?
    private var subscriptions = [String: Subscription]()

    // MARK: - Init

    public init(connection: HubConnectionProtocol, hubName: String) {
        self.connection = connection
        self.hubName = hubName
    }

    // MARK: - Subscribe

    public func on(eventName: String?, handler: @escaping ((_ args: [Any]) -> ())) -> Subscription? {
        guard eventName != nil && !eventName!.isEmpty else {
            NSException.raise(.invalidArgumentException, format: NSLocalizedString("Argument eventName is null", comment: "null event name exception"), arguments: getVaList(["nil"]))
            return nil
        }

        var subscription = self.subscriptions[eventName!]
        if subscription == nil {
            subscription = Subscription()
            subscription?.handler = handler
            self.subscriptions[eventName!] = subscription
        }

        return subscription!
    }

    public func invokeEvent(eventName: String, withArgs args: [Any]) {
        if let subscription = self.subscriptions[eventName], let handler = subscription.handler {
            handler(args)
        }
    }

    // MARK: - Publish

    public func invoke(method: String?, withArgs args: [Any]) {
        self.invoke(method: method, withArgs: args)
    }

    func invoke(method: String?, withArgs args: [Any], completionHandler: ((Any?, Error?) -> ())?) {
        guard method != nil && !method!.isEmpty else {
            NSException.raise(.invalidArgumentException, format: NSLocalizedString("Argument method is null", comment: "null event name exception"), arguments: getVaList(["nil"]))
            return
        }

        let callbackId = self.connection.registerCallback { (result) in
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

        let hubData = HubInvocation()
        hubData.hub = self.hubName!
        hubData.method = method!
        hubData.args = args
        hubData.callbackId = callbackId

        if self.state.count > 0 {
            hubData.state = self.state
        }

        self.connection.send(object: hubData, completionHandler: completionHandler)
    }
}
