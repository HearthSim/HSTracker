//
//  CardSet.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 8/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum CardSet: String, EnumCollection {
    case all, invalid // fake one
    case core, expert1, naxx, gvg, brm,
    tgt, loe, promo, reward, hero_skins,
    og, kara, gangs, ungoro, hof, icecrown,
    lootapalooza
    
    static func deckManagerValidCardSets() -> [CardSet] {
        return [.all, .expert1, .naxx, .gvg, .brm, .tgt,
                .loe, .og, .kara, .gangs, .ungoro, .icecrown,
                .lootapalooza]
    }
    
    static func wildSets() -> [CardSet] {
        return [.naxx, .gvg, .brm, .tgt, .loe, .hof, .promo]
    }
}
