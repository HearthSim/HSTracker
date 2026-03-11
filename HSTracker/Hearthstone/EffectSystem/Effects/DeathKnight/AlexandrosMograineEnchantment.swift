//
//  AlexandrosMograineEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class AlexandrosMograineEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.Deathknight.AlexandrosMograine_MograinesMigraineEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Deathknight.AlexandrosMograine
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .heroModification
    }
}
