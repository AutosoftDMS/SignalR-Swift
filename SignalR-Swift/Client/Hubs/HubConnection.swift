//
//  HubConnection.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

class HubConnection: Connection, HubConnectionProtocol {

    private var hubs = [String: HubProxy]()
    private var callbacks = [String: HubConnectionHubResultClosure]()
    private var callbackId = 0

    override convenience init(withUrl url: String) {
        self.init(withUrl: url, useDefault: true)
    }

    init(withUrl url: String, useDefault: Bool) {
        super.init(withUrl: HubConnection.getUrl(url: url, useDefault: useDefault))
    }

    override convenience init(withUrl url: String, queryString: [String: String]?) {
        self.init(withUrl: url, queryString: queryString, useDefault: true)
    }

    init(withUrl url: String, queryString: [String: String]?, useDefault: Bool) {
        super.init(withUrl: HubConnection.getUrl(url: url, useDefault: useDefault), queryString: queryString)
    }

    func createHubProxy(hubName: String) -> HubProxy? {
        if self.state != .disconnected {
            NSException.raise(.internalInconsistencyException, format: NSLocalizedString("Proxies cannot be added after the connection has been started.", comment: "proxy added after connection starts exception"), arguments: getVaList(["nil"]))
        }

        var proxy: HubProxy? = nil

        if self.hubs[hubName.lowercased()] == nil {
            proxy = HubProxy(connection: self, hubName: hubName.lowercased())
            self.hubs[hubName.lowercased()] = proxy
        }

        return proxy
    }

    func registerCallback(callback: @escaping HubConnectionHubResultClosure) -> String {
        let newId = String(self.callbackId)
        self.callbacks[newId] = callback
        self.callbackId += 1

        return newId
    }

    func removeCallback(callbackId: String) {
        self.callbacks.removeValue(forKey: callbackId)
    }

    func clearInvocationCallbacks(error: String?) {
        let result = HubResult()
        result.error = error

        for callback in self.callbacks.values {
            callback(result)
        }

        self.callbacks.removeAll()
    }

    // MARK: - Private

    static func getUrl(url: String, useDefault: Bool) -> String {
        var urlResult = url
        urlResult = url.hasSuffix("/") ? url : url.appending("/")

        if useDefault {
            return urlResult.appending("signalr")
        }

        return urlResult
    }

    // MARK - Sending Data

    override func onSending() -> String {
        var data = [HubRegistrationData]()
        for key in self.hubs.keys {
            let registration = HubRegistrationData()
            registration.name = key
            data.append(registration)
        }

        return data.toJSONString()!
    }

    // MARK: - Received Data

    override func didReceiveData(data: Any) {

    }

    override func willReconnect() {
        self.clearInvocationCallbacks(error: "Connection started reconnecting before invocation result was received.")
        super.willReconnect()
    }

    override func didClose() {
        self.clearInvocationCallbacks(error: "Connection was disconnected before invocation result was received.")
        super.didClose()
    }
}
