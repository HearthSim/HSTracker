//
//  Task.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/21/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

extension Task<Never, Never> {
    static func sleep(milliseconds: UInt64) async {
        do {
            try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
        } catch {
            logger.error(error)
        }
    }
}
