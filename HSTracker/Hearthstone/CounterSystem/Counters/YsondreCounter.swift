//
//  YsondreCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class YsondreCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Warrior.Ysondre
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Warrior.Ysondre]
    }

    var opponentHadYsondreInPlay: Bool = false

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return (counter > 0 && opponentMayHaveRelevantCards()) || opponentHadYsondreInPlay
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(counter + 1)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard game.isMulliganDone() else { return }

        if entity.cardId != CardIds.Collectible.Warrior.Ysondre { return }
        if tag != .zone { return }

        if value == Zone.play.rawValue {
            if entity[.controller] == game.opponent.id && !isPlayerCounter {
                opponentHadYsondreInPlay = true
            }
            return
        }

        if prevValue != Zone.play.rawValue { return }
        if value != Zone.graveyard.rawValue { return }

        let controller = entity[.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter += 1
        }
    }
}
