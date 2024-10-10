//
//  DeputizationAuraEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DeputizationAuraEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Paladin.DeputizationAura_MyFavoriteDeputyEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Paladin.DeputizationAura
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
        return .minionModification
    }
}
