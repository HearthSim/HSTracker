//
//  Task.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/21/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

@available(macOS 10.15, *)
extension Task<Never, Never> {
    static func sleep(seconds: UInt64) async {
        do {
            try await Task.sleep(nanoseconds: seconds * 1_000_000)
        } catch {
            logger.error(error)
        }
    }
}
