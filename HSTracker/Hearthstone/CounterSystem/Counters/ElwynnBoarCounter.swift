//
//  ElwynnBoarCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/19/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class ElwynnBoarCounter: NumericCounter {

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.ElwynnBoar
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.ElwynnBoar
        ]
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isTraditionalHearthstoneMatch {
            return
        }

        if !game.isMulliganDone() {
            return
        }

        if entity.info.latestCardId != CardIds.Collectible.Neutral.ElwynnBoar {
            return
        }

        if tag != .zone {
            return
        }

        if prevValue != Zone.play.rawValue {
            return
        }

        if value != Zone.graveyard.rawValue {
            return
        }

        let controller = entity[.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter += 1
        }
    }
}
