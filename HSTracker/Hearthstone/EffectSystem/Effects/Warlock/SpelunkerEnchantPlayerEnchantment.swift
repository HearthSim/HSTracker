//
//  SpelunkerEnchantPlayerEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SpelunkerEnchantPlayerEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Warlock.Spelunker_SpelunkerEnchantPlayerEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Warlock.Spelunker
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
