//
//  CardsDrawnThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardsDrawnThisGameCounter: NumericCounter {
    override var cardIdToShowInUI: String {
        CardIds.Collectible.Neutral.PlayhouseGiant
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.PlayhouseGiant
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }

        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        guard let card = Cards.by(cardId: CardIds.Collectible.Neutral.PlayhouseGiant) else {
            return false
        }

        return game.opponent.originalClass == .rogue && CardUtils.isCardFromFormat(card: card, format: game.currentFormat) && counter >= 10
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch, game.isMulliganDone() else {
            return
        }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        guard tag == .zone, prevValue == Zone.deck.rawValue, value == Zone.hand.rawValue else {
            return
        }

        counter += 1
    }
}
