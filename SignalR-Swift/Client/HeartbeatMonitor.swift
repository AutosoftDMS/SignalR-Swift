//
//  HeartbeatMonitor.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

public class HeartbeatMonitor {
    private var beenWarned = false
    var hasBeenWarned: Bool {
        return self.beenWarned
    }

    private var timedOut = false
    var didTimeOut: Bool! {
        return self.timedOut
    }

    private weak var connection: ConnectionProtocol?
    private var timer: Timer?

    init(withConnection connection: ConnectionProtocol) {
        self.connection = connection
    }

    func start() {
        self.connection?.updateLastKeepAlive()
        self.beenWarned = false
        self.timedOut = false
        if let interval = self.connection?.keepAliveData?.checkInterval {
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.heartBeat(withTimer:)), userInfo: nil, repeats: true)
        }
    }

    @objc func heartBeat(withTimer timer: Timer) {
        if let lastKeepAlive = self.connection?.keepAliveData?.lastKeepAlive {
            let date = Date()
            let timeElapsed = date.timeIntervalSince(lastKeepAlive)
            self.beat(timeElapsed: timeElapsed)
        }
    }

    func beat(timeElapsed: Double) {
        if self.connection?.state == .connected, let keepAlive = self.connection?.keepAliveData {
            if timeElapsed >= keepAlive.timeout {
                if self.didTimeOut! {
                    self.timedOut = true
                    self.connection?.transport?.lostConnection(connection: self.connection!)
                }
            } else if timeElapsed >= keepAlive.timeoutWarning {
                if self.hasBeenWarned {
                    self.beenWarned = true
                    self.connection?.connectionDidSlow()
                }
            } else {
                self.beenWarned = false
                self.timedOut = false
            }
        }
    }

    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
}
