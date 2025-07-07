//
//  LohLivingLegendEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class LohLivingLegendEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Druid.LohtheLivingLegend_LivingLegendEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Druid.LohTheLivingLegend
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        .permanent
    }

    override var effectTag: EffectTag {
        .costModification
    }
}
