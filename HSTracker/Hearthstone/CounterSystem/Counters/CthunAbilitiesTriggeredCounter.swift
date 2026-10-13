//
//  CthunAbilitiesTriggeredCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// C'Thun, Eye of the Empire: "Old God. If you've triggered all 4 C'Thun abilities this game, this minion's abilities are tripled."
class CthunAbilitiesTriggeredCounter: NumericCounter {
    private static let abilityCount = 4

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.CthunEyeOfTheEmpire
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.CthunEyeOfTheEmpire
        ]
    }

    private var abilitiesUsed = [Bool](repeating: false, count: CthunAbilitiesTriggeredCounter.abilityCount)

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
        return isPlayerCounter
            ? getCardsInDeckOrKnown(cardIds: relatedCards)
            : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return "\(counter)/\(CthunAbilitiesTriggeredCounter.abilityCount)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        let index: Int
        switch tag {
        case .cthun_ability1_used: index = 0
        case .cthun_ability2_used: index = 1
        case .cthun_ability3_used: index = 2
        case .cthun_ability4_used: index = 3
        default: return
        }
        if value <= 0 {
            return
        }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if abilitiesUsed[index] {
            return
        }

        abilitiesUsed[index] = true
        counter += 1
    }
}
