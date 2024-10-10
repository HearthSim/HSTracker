//
//  TrailMixEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrailMixEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.TrailMix_SugarRushEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.TrailMix
    }
    
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }
    
    override var effectDuration: EffectDuration {
        return .nextTurn
    }
    
    override var effectTag: EffectTag {
        return .manaCrystalModification
    }
}

