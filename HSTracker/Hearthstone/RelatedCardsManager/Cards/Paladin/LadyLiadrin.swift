//
//  LadyLiadrin.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/6/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class LadyLiadrin: ICardWithRelatedCards {
    required init() {
    }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Paladin.LadyLiadrin
    }

    public func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    public func getRelatedCards(player: Player) -> [Card?] {
        return player.spellsPlayedInFriendlyCharacters.map { id in Cards.by(cardId: id) }
    }
}
