//
//  ElementalsExtraStatsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ElementalsExtraStatsCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.SandSwirler
    }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.SandSwirler,
            CardIds.NonCollectible.Neutral.GlowingCinder
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override var localizedName: String {
        return String.localizedString("Counter_ElementalExtraStats", comment: "")
    }

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && (attackCounter > 0 || healthCounter > 0)
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "+\(max(0, attackCounter)) / +\(max(0, healthCounter))"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if tag == .bacon_elemental_buffatkvalue {
            attackCounter = value
        }

        if tag == .bacon_elemental_buffhealthvalue {
            healthCounter = value
        }
    }
}
