//
//  AstralAutomatonCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class AstralAutomatonCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Priest.AstralAutomaton
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Priest.AstralAutomaton]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCards)
        } else {
            return counter > 0 && opponentMayHaveRelevantCards()
        }
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(counter + 1)/\(counter + 2)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag != .zone { return }

        if value != Zone.play.rawValue { return }

        if entity.card.id != CardIds.NonCollectible.Neutral.AstralAutomaton_DefenseMatrixOnlineEnchantment {
            return
        }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter += 1
        }
    }
}
