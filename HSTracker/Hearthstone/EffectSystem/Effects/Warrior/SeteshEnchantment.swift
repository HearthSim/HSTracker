//
//  SeteshEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Gain 20 Armor. In 2 turns, convert your Armor into a Golem with that many stats and Taunt."
class SeteshEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warrior.Setesh_SeteshTrackerEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warrior.Setesh
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .summon
    }
}
