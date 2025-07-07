//
//  GorishisFavorEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class GorishisFavorEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.DemonHunter.UnleashtheColossus_GorishisFavorEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.NonCollectible.DemonHunter.UnleashtheColossus_GorishiColossusToken
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        .permanent
    }

    override var effectTag: EffectTag {
        .damageModification
    }
}
