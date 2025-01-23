//
//  InfestorEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class InfestorEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.Deathknight.Infestor_ForTheSwarmEnchantment1
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Deathknight.Infestor
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .minionModification
    }
}
