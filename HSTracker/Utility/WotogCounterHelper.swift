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
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return nil
        }
        return game.player.playerEntities
                .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.Cthun })
    }

    static var playerCthunProxy: Entity? {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return nil
        }
        return game.player.playerEntities
                .firstWhere({ $0.cardId == CardIds.NonCollectible.Neutral.Cthun })
    }

    static var playerYogg: Entity? {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return nil
        }
        return game.player.playerEntities
                .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.YoggSaronHopesEnd })
    }

    static var playerNzoth: Entity? {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return nil
        }
        return game.player.playerEntities
                .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.NzothTheCorruptor })
    }

    static var playerArcaneGiant: Entity? {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return nil
        }
        return game.player.playerEntities
                .firstWhere({
            $0.cardId == CardIds.Collectible.Neutral.ArcaneGiant
                    && $0.info.originalZone != nil
        })
    }

    static var opponentCthun: Entity? {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return nil
        }
        return game.opponent.playerEntities
                .firstWhere({ $0.cardId == CardIds.Collectible.Neutral.Cthun })
    }

    static var opponentCthunProxy: Entity? {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return nil
        }
        return game.opponent.playerEntities
                .firstWhere({ $0.cardId == CardIds.NonCollectible.Neutral.Cthun })
    }

    static var playerSeenCthun: Bool {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return false
        }
        return game.playerEntity?.has(tag: .seen_cthun) ?? false
    }

    static var opponentSeenCthun: Bool {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return false
        }
        return game.opponentEntity?.has(tag: .seen_cthun) ?? false
    }

    static var playerSeenJade: Bool {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return false
        }
        return game.playerEntity?.has(tag: .jade_golem) ?? false
    }

    static var playerNextJadeGolem: Int {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return 1
        }
        let jade = game.playerEntity?[.jade_golem] ?? 0
        return playerSeenJade ? min(jade + 1, 30) : 1
    }

    static var opponentSeenJade: Bool {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return false
        }
        return game.opponentEntity?.has(tag: .jade_golem) ?? false
    }

    static var opponentNextJadeGolem: Int {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return 1
        }
        let jade = game.opponentEntity?[.jade_golem] ?? 0
        return opponentSeenJade ? min(jade + 1, 30) : 1
    }

    static var cthunInDeck: Bool {
        return deckContains(cardId: CardIds.Collectible.Neutral.Cthun)
    }

    static var yoggInDeck: Bool {
        return deckContains(cardId: CardIds.Collectible.Neutral.YoggSaronHopesEnd)
    }

    static var arcaneGiantInDeck: Bool {
        return deckContains(cardId: CardIds.Collectible.Neutral.ArcaneGiant)
    }

    static var nzothInDeck: Bool {
        return deckContains(cardId: CardIds.Collectible.Neutral.NzothTheCorruptor)
    }

    static var showPlayerCthunCounter: Bool {
        return Settings.instance.showPlayerCthun && playerSeenCthun
    }

    static var showPlayerSpellsCounter: Bool {
        guard Settings.instance.showPlayerSpell else {
            return false
        }

        return (playerYogg != nil || yoggInDeck == true)
                || (playerArcaneGiant != nil || arcaneGiantInDeck == true)
    }

    static var showPlayerDeathrattleCounter: Bool {
        return Settings.instance.showPlayerDeathrattle
                && (playerYogg != nil || nzothInDeck == true)
    }

    static var showPlayerGraveyard: Bool {
        return Settings.instance.showPlayerGraveyard
    }

    static var showPlayerJadeCounter: Bool {
        return Settings.instance.showPlayerJadeCounter && playerSeenJade
    }

    static var showOpponentJadeCounter: Bool {
        return Settings.instance.showOpponentJadeCounter && opponentSeenJade
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

    static var showOpponentGraveyard: Bool {
        return Settings.instance.showOpponentGraveyard
    }

    private static func deckContains(cardId: String) -> Bool {
        guard let game = (NSApp.delegate as? AppDelegate)?.game else {
            return false
        }
        return game.currentDeck?.cards.any({ $0.id == cardId }) ?? false
    }
}
