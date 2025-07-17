//
//  PaladinCardsPlayedCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/17/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PaladinCardsPlayedCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Paladin.Lightray
    }

    override var relatedCards: [String] {
        [CardIds.Collectible.Paladin.Lightray]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        }
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        let controller = entity[.controller]
        if !((controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter)) {
            return
        }

        if discountIfCantPlay(tag: tag, value: value, entity: entity) {
            return
        }

        if tag != .zone {
            return
        }

        if value != Zone.play.rawValue && value != Zone.secret.rawValue {
            return
        }

        if AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type != "PLAY" {
            return
        }

        if entity[.class] != CardClass.allCases.firstIndex(of: .paladin) {
            return
        }

        lastEntityToCount = entity
        counter += 1
    }
}
