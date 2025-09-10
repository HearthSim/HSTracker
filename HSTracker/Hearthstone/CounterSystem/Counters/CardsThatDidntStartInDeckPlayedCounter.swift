//
//  CardsThatDidntStartInDeckPlayedCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardsThatDidntStartInDeckPlayedCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Mage.Techysaurus
    }

    override var relatedCards: [String] {
        [CardIds.Collectible.Mage.Techysaurus]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }
        return isPlayerCounter && inPlayerDeckOrKnown(cardIds: relatedCards)
    }

    override func getCardsToDisplay() -> [String] {
        return getCardsInDeckOrKnown(cardIds: relatedCards)
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isTraditionalHearthstoneMatch {
            return
        }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if !entity.info.created {
            return
        }

        if discountIfCantPlay(tag: tag, value: value, entity: entity) {
            return
        }

        if tag != .zone {
            return
        }

        if prevValue != Zone.hand.rawValue {
            return
        }

        if (value == Zone.play.rawValue || value == Zone.secret.rawValue),
           AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" {
            lastEntityToCount = entity
            counter += 1
        }
    }
}
