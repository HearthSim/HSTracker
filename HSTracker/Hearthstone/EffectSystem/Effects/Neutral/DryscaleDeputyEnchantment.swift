//
//  DryscaleDeputyEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DryscaleDeputyEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.DryscaleDeputy_DryscaleDeputyEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Neutral.DryscaleDeputy
    }

    // Initializer
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    // Computed properties
    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .cardAmount
    }
}
