//
//  SlowMotionEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class SlowMotionEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Warrior.SlowMotion_SlowedDownEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Warrior.SlowMotion
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectTarget: EffectTarget {
        .enemy
    }

    override var effectDuration: EffectDuration {
        .nextTurn
    }

    override var effectTag: EffectTag {
        .costModification
    }
}
