//
//  DiscsOfNorgannonEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Move all spells in your deck to the top. You can pick to draw from the top or bottom each turn."
class DiscsOfNorgannonEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Mage.DiscsofNorgannon_ShiftTheDiscsEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Mage.DiscsOfNorgannon
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
        return .cardAmount
    }
}
