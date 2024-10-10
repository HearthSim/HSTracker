//
//  CorruptingMistEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CorruptingMistEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warlock.CorruptingMist_CorruptingMistEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warlock.CorruptingMist
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var uniqueEffect: Bool {
        return true
    }

    override var effectTarget: EffectTarget {
        return .enemy
    }

    override var effectDuration: EffectDuration {
        return .nextTurn
    }

    override var effectTag: EffectTag {
        return .minionModification
    }
}
