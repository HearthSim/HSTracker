//
//  ProsecutorMeltranixEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class ProsecutorMeltranixEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.DemonHunter.ProsecutorMeltranix_LiterallyUnplayableEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.DemonHunter.ProsecutorMeltranix
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectTarget: EffectTarget { 
        return EffectTarget.enemy
    }
    
    override var effectDuration: EffectDuration { 
        return EffectDuration.nextTurn
    }
    
    override var effectTag: EffectTag { 
        return EffectTag.cardLock
    }
}
