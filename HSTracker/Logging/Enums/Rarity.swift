//
//  Rarity.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Rarity: String {
    case free,
        common,
        rare,
        epic,
        legendary,
        golden

    static func allValues() -> [Rarity] {
        return [.free, .common, .rare, .epic, .legendary]
    }
}
