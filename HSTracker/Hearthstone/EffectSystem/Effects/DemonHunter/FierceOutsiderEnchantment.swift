//
//  FierceOutsiderEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class FierceOutsiderEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.DemonHunter.FierceOutsider_IntrovertedEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.DemonHunter.FierceOutsider
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

