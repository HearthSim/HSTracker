//
//  InventorsAuraEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class InventorsAuraEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Paladin.InventorsAura_EmpoweredWorkshopEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Paladin.InventorsAura
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
