//
//  WhelpStatsBuffCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/12/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class WhelpStatsBuffCounter: StatsCounter {

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.TwilightHatchling_TwilightWhelpToken
    }

    override var localizedName: String {
        return String.localizedString("Counter_WhelpBuff", comment: "")
    }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.BurgeoningWhelp,
            CardIds.NonCollectible.Neutral.TwilightHatchling_TwilightWhelpToken,
            CardIds.NonCollectible.Neutral.BlueWhelp
        ]
    }

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && (attackCounter > 0 || healthCounter > 0)
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "+\(attackCounter) / +\(healthCounter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isBattlegroundsMatch() {
            return
        }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if entity.card.id != CardIds.NonCollectible.Neutral.BurgeoningWhelp_WhelpBuffPlayerEnchantDnt {
            return
        }

        if tag == .tag_script_data_num_1 {
            attackCounter = value
        }

        if tag == .tag_script_data_num_2 {
            healthCounter = value
        }
    }
}
