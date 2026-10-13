//
//  AmmunaeEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: For the rest of the game, after you play a Deathrattle minion, summon a copy of it."
class AmmunaeEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Druid.Ammunae_LifeConstructedEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.Ammunae
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .summon
    }
}
