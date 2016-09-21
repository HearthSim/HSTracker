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
        return Game.instance.player.playerEntities
            .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.Cthun })
    }
    static var playerCthunProxy: Entity? {
        return Game.instance.player.playerEntities
            .firstWhere({ $0.cardId == CardIds.NonCollectible.Neutral.Cthun })
    }
    static var playerYogg: Entity? {
        return Game.instance.player.playerEntities
            .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.YoggSaronHopesEnd })
    }
    static var playerNzoth: Entity? {
        return Game.instance.player.playerEntities
            .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.NzothTheCorruptor })
    }
    static var playerArcaneGiant: Entity? {
        return Game.instance.player.playerEntities
            .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.ArcaneGiant
                && $0.info.originalZone != nil })
    }

    static var opponentCthun: Entity? {
        return Game.instance.opponent.playerEntities
            .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.Cthun })
    }
    static var opponentCthunProxy: Entity? {
        return Game.instance.opponent.playerEntities
            .firstWhere({ $0.cardId == CardIds.NonCollectible.Neutral.Cthun })
    }

    static var playerSeenCthun: Bool {
        return Game.instance.playerEntity?.hasTag(.SEEN_CTHUN) ?? false
    }
    static var opponentSeenCthun: Bool {
        return Game.instance.opponentEntity?.hasTag(.SEEN_CTHUN) ?? false
    }
    static var cthunInDeck: Bool? {
        return deckContains(CardIds.Collectible.Neutral.Cthun)
    }
    static var yoggInDeck: Bool? {
        return deckContains(CardIds.Collectible.Neutral.YoggSaronHopesEnd)
    }
    static var arcaneGiantInDeck: Bool? {
        return deckContains(CardIds.Collectible.Neutral.ArcaneGiant)
    }
    static var nzothInDeck: Bool? {
        return deckContains(CardIds.Collectible.Neutral.NzothTheCorruptor)
    }

    static var showPlayerCthunCounter: Bool {
        return Settings.instance.showPlayerCthun && playerSeenCthun
    }

    static var showPlayerSpellsCounter: Bool {
        guard Settings.instance.showPlayerSpell else { return false }

        return (yoggInDeck != nil && (playerYogg != nil || yoggInDeck == true))
                || (arcaneGiantInDeck != nil
                    && (playerArcaneGiant != nil || arcaneGiantInDeck == true))
    }

    static var showPlayerDeathrattleCounter: Bool {
        return Settings.instance.showPlayerDeathrattle
            && nzothInDeck != nil && (playerYogg != nil || nzothInDeck == true)
    }

    static var showOpponentCthunCounter: Bool {
        return Settings.instance.showOpponentCthun && opponentSeenCthun
    }

    static var showOpponentSpellsCounter: Bool {
        return Settings.instance.showOpponentSpell
    }

    static var showOpponentDeathrattleCounter: Bool {
        return Settings.instance.showOpponentDeathrattle
    }

    private static func deckContains(cardId: String) -> Bool? {
        return Game.instance.activeDeck?.sortedCards.any({ $0.id == cardId })
    }
}
