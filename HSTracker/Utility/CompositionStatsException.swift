//
//  CompositionStatsException.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/18/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct CompositionStatsException: LocalizedError {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var errorDescription: String? {
        description
    }
}
