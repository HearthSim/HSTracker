//
//  HarrowingOxEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class HarrowingOxEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Deathknight.HarrowingOx_OxChillEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Deathknight.HarrowingOx
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
