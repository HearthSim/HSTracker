//
//  BroodqueenShakarEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: If 5 friendly minions died this turn, your Rush minions have Charge this game."
class BroodqueenShakarEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.DemonHunter.BroodqueenShakar_ShakarsRageEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.DemonHunter.BroodqueenShakar
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var uniqueEffect: Bool {
        return true
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .minionModification
    }
}
