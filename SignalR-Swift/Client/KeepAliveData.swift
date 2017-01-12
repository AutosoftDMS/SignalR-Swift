//
//  KeepAliveData.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

public class KeepAliveData {
    var lastKeepAlive: Date?
    var timeout: Double!
    var timeoutWarning: Double!
    var checkInterval: Double!

    init(timeout: Double) {
        self.timeout = timeout
        self.timeoutWarning = timeout * (2 / 3)
        self.checkInterval = timeout - self.timeoutWarning / 3.0
    }

    init(withLastKeepAlive lastKeepAlive: Date, timeout: Double, timeoutWarning: Double, checkInterval: Double) {
        self.lastKeepAlive = lastKeepAlive
        self.timeout = timeout
        self.timeoutWarning = timeoutWarning
        self.checkInterval = checkInterval
    }
}
