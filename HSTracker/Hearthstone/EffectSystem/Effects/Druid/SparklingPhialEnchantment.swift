//
//  SparklingPhialEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SparklingPhialEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Druid.SparklingPhial_SparklingEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.SparklingPhial
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

