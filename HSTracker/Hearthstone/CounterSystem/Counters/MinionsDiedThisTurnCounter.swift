//
//  MinionsDiedThisTurnCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class MinionsDiedThisTurnCounter: NumericCounter {

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Invalid.RemnantOfRage
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Invalid.RemnantOfRage
        ]
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
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isTraditionalHearthstoneMatch {
            return
        }

        if !game.isMulliganDone() {
            return
        }

        if tag == .num_turns_in_play {
            counter = 0
            return
        }

        if !entity.isMinion {
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

        counter += 1
    }
}
