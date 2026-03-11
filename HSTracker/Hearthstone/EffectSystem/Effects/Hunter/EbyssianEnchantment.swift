//
//  EbyssianEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class EbyssianEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.Neutral.Ebyssian_EbyssiansBlessingEnchantment1
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Hunter.Ebyssian
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
