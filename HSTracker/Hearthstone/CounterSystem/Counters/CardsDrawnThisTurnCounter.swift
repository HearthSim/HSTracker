//
//  CardsDrawnThisTurnCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardsDrawnThisTurnCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_CardsDrawnThisTurn", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Rogue.EverythingMustGo
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Rogue.EverythingMustGo,
            CardIds.Collectible.DemonHunter.IreboundBrute,
            CardIds.Collectible.DemonHunter.LionsFrenzy,
            CardIds.Collectible.DemonHunter.Momentum,
            CardIds.Collectible.DemonHunter.ArguniteGolem,
            CardIds.Collectible.DemonHunter.Mindbender
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

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard game.isMulliganDone() else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }

        if tag == .num_turns_in_play {
            counter = 0
            return
        }

        if tag != .zone { return }
        if prevValue != Zone.deck.rawValue { return }
        if value != Zone.hand.rawValue { return }

        counter += 1
    }
}
