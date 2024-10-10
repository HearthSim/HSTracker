//
//  CurseOfWeaknessEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CurseOfWeaknessEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.CurseofWeakness_CurseOfWeaknessEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warlock.CurseOfWeakness
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
