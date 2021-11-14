//
//  MercenariesCollection.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/12/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

struct MercenaryCoinsEntry {
    var id: Int
    var coins: Int
    
    init(id: Int, coins: Int) {
        self.id = id
        self.coins = coins
    }
}

class MercenariesCoins {
    private static var coinsByMercenary = [Int: Int]()
    
    static func update() -> [MercenaryCoinsEntry] {
        var deltas = [MercenaryCoinsEntry]()
        if let data = MirrorHelper.getMercenariesInCollection() {
            for merc in data {
                var delta = merc.currencyAmount.intValue
                if let curr = MercenariesCoins.coinsByMercenary[merc.id.intValue] {
                    delta -= curr
                }
                if delta > 0 {
                    deltas.append(MercenaryCoinsEntry(id: merc.id.intValue, coins: delta))
                }
                coinsByMercenary[merc.id.intValue] = merc.currencyAmount.intValue
            }
        }
        return deltas
    }
}
