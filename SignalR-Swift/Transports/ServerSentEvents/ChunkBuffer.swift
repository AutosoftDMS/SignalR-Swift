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

        while let endIndex = buffer.index(of: "\n") {
            let substring = buffer[..<endIndex]
            buffer.removeSubrange(buffer.startIndex ..< buffer.index(after: endIndex))

            if !substring.isEmpty {
                line = String(substring)
                break
            }
        }

        return line
    }
}
