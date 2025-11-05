//
//  MurlocRafaamEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class MurlocRafaamEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Warlock.TimethiefRafaam_MrgleermMrgloslgyToken
    }

    override var cardIdToShowInUI: String {
        CardIds.NonCollectible.Warlock.TimethiefRafaam_MurlocRafaamToken
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        .conditional
    }

    override var effectTag: EffectTag {
        .costModification
    }
}
