//
//  ChunkBuffer.swift
//  SignalR-Swift
//
//  Created by Vladimir Kushelkov on 21/07/2017.
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import Foundation

final class ChunkBuffer {
    private var buffer = String()
    
    var hasChunks: Bool {
        return !buffer.isEmpty
    }
    
    func append(data: Data) {
        guard let newChunk = String(data: data, encoding: .utf8), !newChunk.isEmpty else { return }
        buffer.append(newChunk)
    }
    
    func readLine() -> String? {
        var line: String?
        var lineEndIndex: String.Index?
        
        buffer.enumerateSubstrings(in: buffer.startIndex ..< buffer.endIndex, options: .byLines) {
            substring, substringRange, enclosingRange, stop in
            guard let substring = substring, !substring.isEmpty else { return }
            
            line = substring
            lineEndIndex = enclosingRange.upperBound
            stop = true
        }
        
        if let endIndex = lineEndIndex {
            buffer.removeSubrange(buffer.startIndex ..< endIndex)
        }
        
        return line
    }
}
