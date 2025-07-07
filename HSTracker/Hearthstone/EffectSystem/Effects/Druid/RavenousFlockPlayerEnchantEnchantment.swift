//
//  RavenousFlockPlayerEnchantEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class RavenousFlockPlayerEnchantEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Druid.RavenousFlock_RavenousFlockPlayerEnchantEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Druid.RavenousFlock
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        .nextTurn
    }

    override var effectTag: EffectTag {
        .summon
    }
}
