//
//  WarpGateEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class WarpGateEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.WarpGate_WarpConduitEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Invalid.WarpGate
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
