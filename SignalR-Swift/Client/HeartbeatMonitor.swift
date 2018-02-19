//
//  HeartbeatMonitor.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

public final class HeartbeatMonitor {

    private(set) var hasBeenWarned = false
    private(set) var didTimeOut = false
    private var timer: Timer?
    private unowned let connection: ConnectionProtocol

    init(withConnection connection: ConnectionProtocol) {
        self.connection = connection
    }

    func start() {
        self.connection.updateLastKeepAlive()
        self.hasBeenWarned = false
        self.didTimeOut = false
        if let interval = self.connection.keepAliveData?.checkInterval {
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(heartBeat(_:)), userInfo: nil, repeats: true)
        }
    }

    @objc func heartBeat(_ timer: Timer) {
        guard let lastKeepAlive = connection.keepAliveData?.lastKeepAlive else { return }

        let timeElapsed = Date().timeIntervalSince(lastKeepAlive)
        self.beat(timeElapsed: timeElapsed)
    }

    func beat(timeElapsed: Double) {
        guard self.connection.state == .connected, let keepAlive = self.connection.keepAliveData else { return }

        if timeElapsed >= keepAlive.timeout {
            if !self.didTimeOut {
                self.didTimeOut = true
                self.connection.transport?.lostConnection(connection: self.connection)
            }
        } else if timeElapsed >= keepAlive.timeoutWarning {
            if !self.hasBeenWarned {
                self.hasBeenWarned = true
                self.connection.connectionDidSlow()
            }
        } else {
            self.hasBeenWarned = false
            self.didTimeOut = false
        }
    }

    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
}
