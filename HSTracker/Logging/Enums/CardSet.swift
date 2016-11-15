//
//  CardSet.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 8/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

// swiftlint:disable type_name
enum CardSet: String {
    case all // fake one
    case core, expert1, naxx, gvg, brm,
    tgt, loe, promo, reward, hero_skins,
    og, kara
    
    static func allValues() -> [CardSet] {
        return [.core, .expert1, .naxx, .gvg, .brm,
                .tgt, .loe, .promo, .reward, .hero_skins,
                .og, .kara]
    }
    
    static func deckManagerValidCardSets() -> [CardSet] {
        return [.all, .expert1, .naxx, .gvg, .brm, .tgt, .loe, .og, .kara]
    }
    
    static func wildSets() -> [CardSet] {
        return [.naxx, .gvg]
    }
}
