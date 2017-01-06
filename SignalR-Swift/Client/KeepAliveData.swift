//
//  KeepAliveData.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

class KeepAliveData {
    var lastKeepAlive: Date?
    var timeout: Int!
    var timeoutWarning: Int!
    var checkInterval: Double!

    init(timeout: Int) {
        self.timeout = timeout
        self.timeoutWarning = timeout * ( 2 / 3)
        self.checkInterval = Double(timeout - self.timeoutWarning) / 3.0
    }

    init(withLastKeepAlive lastKeepAlive: Date, timeout: Int, timeoutWarning: Int, checkInterval: Double) {
        self.lastKeepAlive = lastKeepAlive
        self.timeout = timeout
        self.timeoutWarning = timeoutWarning
        self.checkInterval = checkInterval
    }
}
