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
    var checkInterval: Int!

    init(timeout: Int) {
        self.timeout = timeout
        self.timeoutWarning = timeout * ( 2 / 3)
        self.checkInterval = (timeout - self.timeoutWarning) / 3
    }

    init(withLastKeepAlive lastKeepAlive: Date, timeout: Int, timeoutWarning: Int, checkInterval: Int) {
        self.lastKeepAlive = lastKeepAlive
        self.timeout = timeout
        self.timeoutWarning = timeoutWarning
        self.checkInterval = checkInterval
    }
}
