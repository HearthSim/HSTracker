//
//  PopularPixieEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PopularPixieEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.PopularPixie_GladesGuidanceEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.PopularPixie
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

