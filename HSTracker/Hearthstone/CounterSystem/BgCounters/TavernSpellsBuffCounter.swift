//
//  TavernSpellsBuffCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TavernSpellsBuffCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.ShinyRing
    }

    override var localizedName: String {
        return String.localizedString("Counter_TavernSpellsBuff", comment: "")
    }

    override var relatedCards: [String] {
        return []
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && (attackCounter > 1 || healthCounter > 1)
    }

    override func getCardsToDisplay() -> [String] {
        return [
            CardIds.NonCollectible.Neutral.IntrepidBotanist,
            CardIds.NonCollectible.Neutral.TranquilMeditative,
            CardIds.NonCollectible.Neutral.ShoalfinMystic,
            CardIds.NonCollectible.Neutral.Humongozz,
            CardIds.NonCollectible.Neutral.FelfireConjurer
        ]
    }

    override func valueToShow() -> String {
        return "+\(attackCounter) / +\(healthCounter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if !entity.isPlayer(eventHandler: game) {
            return
        }

        switch tag {
        case .tavern_spell_attack_increase:
            attackCounter = value
            onCounterChanged()
        case .tavern_spell_health_increase:
            healthCounter = value
            onCounterChanged()
        default:
            break
        }
    }
}
