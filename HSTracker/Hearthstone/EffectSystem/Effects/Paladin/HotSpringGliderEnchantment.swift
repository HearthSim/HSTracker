//
//  HotSpringGliderEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HotSpringGliderEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Paladin.HotSpringGlider_WeeeeeEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Paladin.HotSpringGlider
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        .conditional
    }

    override var effectTag: EffectTag {
        .costModification
    }
}
