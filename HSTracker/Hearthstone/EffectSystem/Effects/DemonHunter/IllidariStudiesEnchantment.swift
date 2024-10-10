//
//  IllidariStudiesEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

public class IllidariStudiesEnchantment: EntityBasedEffect {
    public override var cardId: String {
        return CardIds.NonCollectible.Neutral.IllidariStudies_LonerEnchantmentDARKMOON_FAIRE2
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.DemonHunter.IllidariStudies
    }
    
    public required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }
    
    public override var effectDuration: EffectDuration {
        return .conditional
    }
    
    public override var effectTag: EffectTag {
        return .costModification
    }
}

