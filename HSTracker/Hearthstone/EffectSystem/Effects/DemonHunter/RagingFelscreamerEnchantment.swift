//
//  RagingFelscreamerEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class RagingFelscreamerEnchantment: EntityBasedEffect {
    override var cardId: String { 
        return CardIds.NonCollectible.DemonHunter.RagingFelscreamer_FelscreamEnchantmentDEMON_HUNTER_INITIATE1
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.DemonHunter.RagingFelscreamerCore
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration { 
        return EffectDuration.conditional
    }
    
    override var effectTag: EffectTag {
        return EffectTag.costModification
    }
}
