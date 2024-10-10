//
//  DiscipleOfEonarEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class DiscipleOfEonarEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.DiscipleofEonar_SymbioticEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.DiscipleOfEonar
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    public override var effectDuration: EffectDuration {
        return EffectDuration.conditional
    }
    
    public override var effectTag: EffectTag {
        return EffectTag.cardActivation
    }
}
