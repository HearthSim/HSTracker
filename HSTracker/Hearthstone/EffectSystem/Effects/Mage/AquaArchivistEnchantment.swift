//
//  AquaArchivistEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class AquaArchivistEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.AquaArchivist_AncientWatersEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Mage.AquaArchivist
    }

    // Initializer
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    // Computed properties
    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
