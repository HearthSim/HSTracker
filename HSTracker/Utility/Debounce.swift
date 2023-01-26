//
//  Debounce.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

@available(macOS 10.15.0, *)
class Debounce {
    private static var _debounces = SynchronizedDictionary<String, Int>()
    
    public static func wasCalledAgain(milliseconds: Int, callerMemberName: String = #function, callerFilePath: String = #filePath) async -> Bool {
        let id = "\(callerMemberName).\(callerFilePath)"
        if let c = _debounces[id] {
            _debounces[id] = c + 1
        } else {
            _debounces[id] = 0
        }
        let count = _debounces[id]
        do {
            try await Task.sleep(nanoseconds: UInt64(1_000_000 * milliseconds))
        } catch {
            logger.error(error)
        }
        return _debounces[id] != count
    }
}
