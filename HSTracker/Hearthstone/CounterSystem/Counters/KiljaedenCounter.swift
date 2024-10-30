//
//  KiljaedenCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/30/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class KiljaedenCounter: StatsCounter {
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.Kiljaeden
    }

    override var relatedCards: [String] {
        return []
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isTraditionalHearthstoneMatch && (attackCounter > 0 || healthCounter > 0)
    }

    override func getCardsToDisplay() -> [String] {
        return [CardIds.Collectible.Neutral.Kiljaeden]
    }

    override func valueToShow() -> String {
        return "+\(max(0, attackCounter)) / +\(max(0, healthCounter))"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard entity.card.id == CardIds.NonCollectible.Neutral.Kiljaeden_KiljaedensPortalEnchantment else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }

        attackCounter = entity[.tag_script_data_num_2]
        healthCounter = entity[.tag_script_data_num_2]
    }
}
