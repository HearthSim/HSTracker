//
//  AscentOfYoggSaron.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Transform spells in your hand into ones that cost (3) more. (They keep their original Cost.)"
// Mastermind Yogg-Saron's ability.
class AscentOfYoggSaron: RelativeCostPoolCard {
    override func getCardId() -> String { CardIds.NonCollectible.Neutral.MastermindYoggSaron_AscentOfYoggSaronToken }
    override var costOffset: Int { 3 }
    override var targetSource: RelativeCostTargetSource { .handSpells }
    override func isInPool(_ card: Card) -> Bool { card.type == .spell }
    override var poolCacheKey: String { "spells" }
}
