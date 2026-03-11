//
//  AlexstraszaGuardianOfLifeEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class AlexstraszaGuardianOfLifeEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.Neutral.AlexstraszaGuardianofLife_CleansedOfCorruptionEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Priest.AlexstraszaGuardianOfLife
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .damageModification
    }
}
