//
//  Sampling.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/24/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Sampling {
    static func shouldSample(_ rate: Double) -> Bool {
        if rate <= 0 {
            return false
        }
        return Double.random(in: 0..<1) < rate
    }
}
