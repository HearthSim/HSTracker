//
//  CardClass.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 13/07/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum CardClass: String, Codable {
    case invalid,
         deathknight,
         druid,
         hunter,
         mage,
         paladin,
         priest,
         rogue,
         shaman,
         warlock,
         warrior,
         dream,
         neutral,
         whizbang,
         demonhunter
    
    var defaultHeroCardId: String {
        switch self {
        case .neutral:
            return ""
        case .druid:
            return CardIds.Collectible.Druid.MalfurionStormrage
        case .hunter:
            return CardIds.Collectible.Hunter.Rexxar
        case .mage:
            return CardIds.Collectible.Mage.JainaProudmoore
        case .paladin:
            return CardIds.Collectible.Paladin.UtherLightbringer
        case .priest:
            return CardIds.Collectible.Priest.AnduinWrynn
        case .rogue:
            return CardIds.Collectible.Rogue.ValeeraSanguinar
        case .shaman:
            return CardIds.Collectible.Shaman.Thrall
        case .warlock:
            return CardIds.Collectible.Warlock.Guldan
        case .warrior:
            return CardIds.Collectible.Warrior.GarroshHellscream
        case .demonhunter:
            return CardIds.Collectible.DemonHunter.Illidan
        case .whizbang:
            return CardIds.Collectible.Neutral.WhizbangTheWonderful
        default:
            return ""
        }
    }
}
