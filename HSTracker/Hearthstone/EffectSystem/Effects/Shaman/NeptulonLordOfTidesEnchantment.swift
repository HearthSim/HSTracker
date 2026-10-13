//
//  NeptulonLordOfTidesEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: For the rest of the game, Elementals you summon have their stats set to 5/5."
class NeptulonLordOfTidesEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Shaman.NeptulonLordofTides_TidalSurgeEnchantment2
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Shaman.NeptulonLordOfTides
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var uniqueEffect: Bool {
        return true
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .minionModification
    }
}
