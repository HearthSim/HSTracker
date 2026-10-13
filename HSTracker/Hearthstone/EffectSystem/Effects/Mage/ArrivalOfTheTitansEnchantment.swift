//
//  ArrivalOfTheTitansEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Draw 2 spells. Refresh 6 Mana Crystals. You can only play spells for the rest of the turn."
class ArrivalOfTheTitansEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Mage.ArrivaloftheTitans_TitansWatchEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Mage.ArrivalOfTheTitans
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var uniqueEffect: Bool {
        return true
    }

    override var effectDuration: EffectDuration {
        return .sameTurn
    }

    override var effectTag: EffectTag {
        return .cardLock
    }
}
