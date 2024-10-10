//
//  ResistanceAuraEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ResistanceAuraEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Paladin.ResistanceAura_ResistanceCoreEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Paladin.ResistanceAuraCore
    }

    // Initializer
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    // Computed properties
    override var effectTarget: EffectTarget {
        return .enemy
    }

    override var effectDuration: EffectDuration {
        return .multipleTurns
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
