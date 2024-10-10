//
//  CloakofShadowsEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CloakofShadowsEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Rogue.CloakofShadows_SneakyEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Rogue.CloakOfShadows
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
