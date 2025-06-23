//
//  LadyDarkvein.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class LadyDarkvein: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Warlock.LadyDarkvein
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        let lastShadowSpell = player.spellsPlayedCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .last(where: { $0.spellSchool == SpellSchool.shadow })

        return lastShadowSpell != nil ? [lastShadowSpell] : []
    }
}

class LadyDarkveinCorePlaceholder: LadyDarkvein {
    override func getCardId() -> String {
        CardIds.Collectible.Warlock.LadyDarkveinCorePlaceholder
    }
}
