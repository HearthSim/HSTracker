//
//  ArrivalOfTheOldGodsEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Draw 2 minions. Refresh 5 Mana Crystals. You can only play minions for the rest of the turn."
class ArrivalOfTheOldGodsEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Deathknight.ArrivaloftheOldGods_OldGodsWatchEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Deathknight.ArrivalOfTheOldGods
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
