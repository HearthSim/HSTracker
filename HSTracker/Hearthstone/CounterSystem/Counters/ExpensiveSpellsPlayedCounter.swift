//
//  ExpensiveSpellsPlayedCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Dragoncaller Alanna: "Battlecry: Summon a 5/5 Dragon for each spell you cast this game
// that costs (5) or more." The value is the number of dragons the battlecry would summon.
class ExpensiveSpellsPlayedCounter: NumericCounter {
    private static let minimumCost = 5

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Mage.DragoncallerAlanna
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Mage.DragoncallerAlanna
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }

        return isPlayerCounter && inPlayerDeckOrKnown(cardIds: relatedCards)
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter
            ? getCardsInDeckOrKnown(cardIds: relatedCards)
            : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
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

        if !entity.isSpell {
            return
        }

        if entity.latestCard.cost < ExpensiveSpellsPlayedCounter.minimumCost {
            return
        }

        counter += 1
    }
}
