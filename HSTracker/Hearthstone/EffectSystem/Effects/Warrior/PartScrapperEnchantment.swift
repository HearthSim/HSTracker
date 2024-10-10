//
//  PartScrapperEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PartScrapperEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warrior.PartScrapper_ScrappedPartsEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warrior.PartScrapper
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
