//
//  CleansingClericEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class CleansingClericEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.Priest.CleansingCleric_FreeFromCorruptionEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Priest.CleansingCleric
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .healingModification
    }
}
