//
//  ExceptionHelper.swift
//  SignalR-Swift
//
//  
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

class ExceptionHelper {

    static func isRequestAborted(error: NSError?) -> Bool {
        return error != nil && error!.code == NSURLErrorCancelled
    }
}
