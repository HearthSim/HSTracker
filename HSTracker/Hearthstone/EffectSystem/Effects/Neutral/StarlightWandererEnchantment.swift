//
//  StarlightWandererEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/30/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class StarlightWandererEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.StarlightWanderer_StarlightWandererFutureBuffEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Neutral.StarlightWanderer
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .minionModification
    }
}
