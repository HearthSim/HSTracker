//
//  LoveEverlastingEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class LoveEverlastingEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Priest.LoveEverlasting_EverlastingLoveEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Priest.LoveEverlasting
    }

    // Initializer
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    // Computed properties
    override var effectDuration: EffectDuration {
        return .multipleTurns
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
