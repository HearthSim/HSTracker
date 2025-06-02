//
//  SpellsPlayedInCharactersCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/16/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SpellsPlayedInCharactersCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Paladin.SeaShanty
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Paladin.SeaShanty]
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
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }

    override func valueToShow() -> String {
        return String(counter)
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

        if tag != .zone || (value != Zone.play.rawValue && value != Zone.secret.rawValue) {
            return
        }

        guard let currentBlock = AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock, currentBlock.type == "PLAY" else { return }
        guard entity.isSpell else { return }

        guard entity.has(tag: .card_target),
              game.entities[entity[.card_target]] != nil else {
            return
        }

        lastEntityToCount = entity
        counter += 1
    }
}
