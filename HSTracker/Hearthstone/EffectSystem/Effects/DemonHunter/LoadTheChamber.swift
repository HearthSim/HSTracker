//
//  LoadTheChamber.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class LoadTheChamber: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.DemonHunter.LoadtheChamber_LoadedNagaEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.DemonHunter.LoadTheChamber
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
