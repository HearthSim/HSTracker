//
//  InfestTheSculleryCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/25/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class InfestTheSculleryCounter: NumericCounter {

    private let baseCost = 3

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Druid.InfestTheScullery
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Druid.InfestTheScullery]
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
        return relatedCards
    }

    override func valueToShow() -> String {
        return String(min(baseCost + counter, 10))
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard tag == .attacking && value != 0 else { return }
        guard entity.isHero else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }

        counter += 1
    }
}
