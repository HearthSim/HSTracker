//
//  ElderWordFlayEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Deal 3 damage to a random enemy. (The next Shadow spell you play repeats this!)"
class ElderWordFlayEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Priest.ElderWordFlay_FlayEssenceEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Priest.ElderWordFlay
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .cardActivation
    }
}
