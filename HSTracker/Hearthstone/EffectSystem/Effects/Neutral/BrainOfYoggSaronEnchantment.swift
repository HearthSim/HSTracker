//
//  BrainOfYoggSaronEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Mastermind Yogg-Saron ability: Your next spell this turn casts twice."
class BrainOfYoggSaronEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Shaman.MastermindYoggSaron_BrainyToken
    }

    override var cardIdToShowInUI: String {
        return CardIds.NonCollectible.Neutral.MastermindYoggSaron_BrainOfYoggSaronToken
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .sameTurn
    }

    override var effectTag: EffectTag {
        return .cardActivation
    }
}
