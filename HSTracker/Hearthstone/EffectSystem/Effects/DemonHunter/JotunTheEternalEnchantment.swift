//
//  JotunTheEternalEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class JotunTheEternalEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.DemonHunter.JotuntheEternal_JotunsSwiftnessToken
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.DemonHunter.JotunTheEternal
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return EffectDuration.permanent
    }
    
    override var effectTag: EffectTag {
        return EffectTag.cardActivation
    }
}

