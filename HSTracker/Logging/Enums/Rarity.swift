//
//  Rarity.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Rarity: String {
    case Free = "free",
        Common = "common",
        Rare = "rare",
        Epic = "epic",
        Legendary = "legendary",
        Golden = "golden"

    static func allValues() -> [Rarity] {
        return [.Free, .Common, .Rare, .Epic, .Legendary]
    }
}
