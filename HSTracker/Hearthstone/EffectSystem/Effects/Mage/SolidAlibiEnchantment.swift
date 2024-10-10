//
//  SolidAlibiEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SolidAlibiEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Mage.SolidAlibi_SolidAlibiEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Mage.SolidAlibi
    }

    // Initializer
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    // Computed properties
    override var effectDuration: EffectDuration {
        return .nextTurn
    }

    override var effectTag: EffectTag {
        return .heroModification
    }
}
