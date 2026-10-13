//
//  TomeTranslatorEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Tome Translator (deciphered): Battlecry: The next spell you cast this turn costs (4) less."
class TomeTranslatorEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Druid.TomeTranslator_YoggScriptureEnchantmentToken
    }

    override var cardIdToShowInUI: String {
        return CardIds.NonCollectible.Neutral.TomeTranslator_TomeTranslatorToken2
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
