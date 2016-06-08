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
    case ALL // fake one
    case CORE, EXPERT1, NAXX, GVG, BRM,
    TGT, LOE, PROMO, REWARD, HERO_SKINS,
    OG
    
    static func allValues() -> [CardSet] {
        return [.CORE, .EXPERT1, .NAXX, .GVG, .BRM,
                .TGT, .LOE, .PROMO, .REWARD, .HERO_SKINS,
                .OG]
    }
    
    static func deckManagerValidCardSets() -> [CardSet] {
        return [.ALL, .EXPERT1, .NAXX, .GVG, .BRM, .TGT, .LOE, .OG]
    }
    
    static func wildSets() -> [CardSet] {
        return [.NAXX, .GVG]
    }
}