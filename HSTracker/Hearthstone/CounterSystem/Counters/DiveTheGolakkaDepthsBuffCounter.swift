//
//  DiveTheGolakkaDepthsBuffCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/8/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DiveTheGolakkaDepthsBuffCounter: StatsCounter {
    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Paladin.DiveTheGolakkaDepths
    }

    override var relatedCards: [String] {
        []
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        game.isTraditionalHearthstoneMatch && (attackCounter > 0 || healthCounter > 0)
    }

    override func getCardsToDisplay() -> [String] {
        [CardIds.Collectible.Paladin.DiveTheGolakkaDepths]
    }

    override func valueToShow() -> String {
        "+\(max(0, attackCounter)) / +\(max(0, healthCounter))"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch,
              entity.card.id == CardIds.Collectible.Paladin.DiveTheGolakkaDepths,
              entity.isControlled(by: game.player.id) == isPlayerCounter,
              tag == .tag_script_data_num_1 else {
            return
        }

        attackCounter = entity[.tag_script_data_num_1]
        healthCounter = entity[.tag_script_data_num_1]
    }
}
