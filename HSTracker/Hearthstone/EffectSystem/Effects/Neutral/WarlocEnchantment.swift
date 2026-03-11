//
//  WarlocEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class WarlocEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.Neutral.Warloc_DoomEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.Warloc
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
