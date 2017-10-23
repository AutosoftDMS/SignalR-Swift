//
//  HubConnection.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation
import Alamofire

public class HubConnection: Connection, HubConnectionProtocol {

    private var hubs = [String: HubProxy]()
    private var callbacks = [String: HubConnectionHubResultClosure]()
    private var callbackId = UInt.min
    
    public init(withUrl url: String,
                queryString: [String: String]? = nil,
                sessionManager: SessionManager = .default,
                useDefault: Bool = true) {
        super.init(withUrl: HubConnection.getUrl(url: url, useDefault: useDefault),
                   queryString: queryString,
                   sessionManager: sessionManager)
    }

    public func createHubProxy(hubName: String) -> HubProxy? {
        if self.state != .disconnected {
            NSException.raise(.internalInconsistencyException, format: NSLocalizedString("Proxies cannot be added after the connection has been started.", comment: "proxy added after connection starts exception"), arguments: getVaList(["nil"]))
        }
        
        let hubName = hubName.lowercased()
        
        guard self.hubs[hubName] == nil else { return nil }
        
        let proxy = HubProxy(connection: self, hubName: hubName)
        self.hubs[hubName] = proxy
        return proxy
    }

    public func registerCallback(callback: @escaping HubConnectionHubResultClosure) -> String {
        let newId = String(self.callbackId)
        self.callbacks[newId] = callback
        self.callbackId += 1

        return newId
    }

    public func removeCallback(callbackId: String) {
        self.callbacks.removeValue(forKey: callbackId)
    }

    func clearInvocationCallbacks(error: String?) {
        let result = HubResult(error: error)

        for (_, callback) in self.callbacks {
            callback(result)
        }

        self.callbacks.removeAll()
    }

    // MARK: - Private

    static func getUrl(url: String, useDefault: Bool) -> String {
        let urlResult = url.hasSuffix("/") ? url : url.appending("/")
        return useDefault ? urlResult.appending("signalr") : urlResult
    }

    // MARK - Sending Data

    override public func onSending() -> String {
        let hubNames = self.hubs.map { (key, _) in ["Name": key] }
        let data = try! JSONSerialization.data(withJSONObject: hubNames)
        return String(data: data, encoding: .utf8)!
    }

    // MARK: - Received Data

    override public func didReceiveData(data: Any) {
        guard let dict = data as? [String: Any]  else { return }
        
        if dict["I"] != nil {
            let result = HubResult(jsonObject: dict)
            if let callback = self.callbacks[result.id!] {
                callback(result)
                return
            }
        }
        
        let invocation = HubInvocation(jsonObject: dict)
        
        if let hubProxy = self.hubs[invocation.hub.lowercased()] {
            invocation.state.forEach { (key, value) in hubProxy.state[key] = value }
            
            hubProxy.invokeEvent(eventName: invocation.method, withArgs: invocation.args)
        }

        super.didReceiveData(data: data)
    }

    override public func willReconnect() {
        self.clearInvocationCallbacks(error: "Connection started reconnecting before invocation result was received.")
        super.willReconnect()
    }

    override func didClose() {
        self.clearInvocationCallbacks(error: "Connection was disconnected before invocation result was received.")
        super.didClose()
    }
}
