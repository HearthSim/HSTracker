//
//  CardSet.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 8/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum CardSet: String, CaseIterable {
    case all, invalid // fake one
    case core,
    expert1,
    naxx,
    gvg,
    brm,
    tgt,
    loe,
    promo,
    reward,
    hero_skins,
    og,
    kara,
    gangs,
    ungoro,
    hof,
    icecrown, // Knights of the frozen Throne
    lootapalooza, // Kobolds & Catacombs
    gilneas, // witchwood
    taverns_of_time,
    boomsday,
    troll, // Rastakhan's Rumble
    dalaran, // rise of the shadows
    uldum, // Saviors of Uldmu
    wild_event,
    dragons // Descent of Dragons
    
    static func deckManagerValidCardSets() -> [CardSet] {
        return [.all, .expert1, .naxx, .gvg, .brm, .tgt,
                .loe, .og, .kara, .gangs, .ungoro, .icecrown,
                .lootapalooza, .gilneas, .boomsday, .troll,
                .dalaran, .uldum, .dragons]
    }
    
    static func wildSets() -> [CardSet] {
        return [.naxx, .gvg, .brm, .tgt, .loe, .hof, .promo,
                .og, .kara, .gangs, .lootapalooza,
                .ungoro, .icecrown, .lootapalooza]
    }
}
