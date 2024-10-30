//
//  SpacerockCollectorEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/30/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SpacerockCollectorEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Rogue.SpacerockCollector_RockCollectionEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Rogue.SpacerockCollector
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
