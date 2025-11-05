//
//  TheEternalHoldEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TheEternalHoldEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.DemonHunter.TheEternalHold_JailbreakEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.DemonHunter.TheEternalHold
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
