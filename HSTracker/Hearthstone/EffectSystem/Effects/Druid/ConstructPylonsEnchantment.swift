//
//  ConstructPylonsEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructPylonsEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Druid.ConstructPylons_PsionicMatrixEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Druid.ConstructPylons
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }
}
