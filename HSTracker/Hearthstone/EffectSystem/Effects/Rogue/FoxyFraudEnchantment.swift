//
//  FoxyFraudEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FoxyFraudEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Rogue.FoxyFraud_EnablingEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Rogue.FoxyFraud
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .sameTurn
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
