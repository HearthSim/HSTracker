//
//  ElderWordManifestEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Summon a 5/5 Voidwing with Lifesteal. (The next Shadow spell you play repeats this!)"
class ElderWordManifestEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Priest.ElderWordManifest_ManifestEssenceEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Priest.ElderWordManifest
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .cardActivation
    }
}
