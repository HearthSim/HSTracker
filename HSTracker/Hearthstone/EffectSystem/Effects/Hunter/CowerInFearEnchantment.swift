//
//  CowerInFearEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CowerInFearEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Hunter.CowerinFear_CowerInFearPlayerEnchantEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Hunter.CowerInFear
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        .sameTurn
    }

    override var effectTag: EffectTag {
        .costModification
    }
}
