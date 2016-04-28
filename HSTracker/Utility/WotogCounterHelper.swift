//
//  WotogCounterHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/04/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class WotogCounterHelper {
    static var playerCthun: Entity? {
        return Game.instance.player.playerEntities.firstWhere({ $0.cardId == CardIds.Collectible.Neutral.Cthun })
    }
    static var playerCthunProxy: Entity? {
        return Game.instance.player.playerEntities.firstWhere({ $0.cardId == CardIds.NonCollectible.Neutral.Cthun })
    }
    static var playerYogg: Entity? {
        return Game.instance.player.playerEntities.firstWhere({ $0.cardId == CardIds.Collectible.Neutral.YoggSaronHopesEnd })
    }
    static var opponentCthun: Entity? {
        return Game.instance.opponent.playerEntities.firstWhere({ $0.cardId == CardIds.Collectible.Neutral.Cthun })
    }
    static var opponentCthunProxy: Entity? {
        return Game.instance.opponent.playerEntities.firstWhere({ $0.cardId == CardIds.NonCollectible.Neutral.Cthun })
    }
    
    static var playerSeenCthun: Bool { return Game.instance.playerEntity?.hasTag(.SEEN_CTHUN) ?? false }
    static var opponentSeenCthun: Bool { return Game.instance.opponentEntity?.hasTag(.SEEN_CTHUN) ?? false }
    static var cthunInDeck: Bool? { return deckContains(CardIds.Collectible.Neutral.Cthun) }
    static var yoggInDeck: Bool? { return deckContains(CardIds.Collectible.Neutral.YoggSaronHopesEnd) }
    
    static var showPlayerCthunCounter: Bool {
        return Settings.instance.showPlayerCthun && playerSeenCthun
    }
    
    static var showPlayerSpellsCounter: Bool {
        return Settings.instance.showPlayerYogg && yoggInDeck != nil && (playerYogg != nil || yoggInDeck == true)
    }
    
    static var showOpponentCthunCounter: Bool {
        return Settings.instance.showOpponentCthun && opponentSeenCthun
    }
    
    static var showOpponentSpellsCounter: Bool {
        return Settings.instance.showOpponentYogg
    }
    
    private static func deckContains(cardId: String) -> Bool? {
        return Game.instance.activeDeck?.sortedCards.any({ $0.id == cardId })
    }
}