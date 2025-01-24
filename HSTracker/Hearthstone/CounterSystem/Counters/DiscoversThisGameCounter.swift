//
//  DiscoversThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DiscoversThisGameCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Hunter.AlienEncounters
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Hunter.AlienEncounters
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 1 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleChoicePicked(choice: IHsCompletedChoice) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        guard let source = game.entities[choice.sourceEntityId], source[.discover] > 0 else { return }

        let controller = source[GameTag.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter += 1
        }
    }
}
