//
//  BloodGemCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BloodGemCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.BloodGem1
    }

    override var relatedCards: [String] {
        return []
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && (attackCounter > 3 || healthCounter > 3)
    }

    override func getCardsToDisplay() -> [String] {
        return [CardIds.NonCollectible.Neutral.BloodGem1]
    }

    override func valueToShow() -> String {
        return "+\(max(1, attackCounter)) / +\(max(1, healthCounter))"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }

        if entity.isControlled(by: game.player.id) == isPlayerCounter {
            if tag == .bacon_bloodgembuffatkvalue {
                attackCounter = value + 1
            }

            if tag == .bacon_bloodgembuffhealthvalue {
                healthCounter = value + 1
            }
        }
    }
}
