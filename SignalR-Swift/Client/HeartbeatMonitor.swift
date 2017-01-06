//
//  HeartbeatMonitor.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

class HeartbeatMonitor {
    private var hasBeenWarned = false
    var beenWarned: Bool! {
        return self.hasBeenWarned
    }

    private var connection: ConnectionProtocol!
    private var timer: Timer?

    init(withConnection connection: ConnectionProtocol) {
        self.connection = connection
    }

    func start() {
    }
}
