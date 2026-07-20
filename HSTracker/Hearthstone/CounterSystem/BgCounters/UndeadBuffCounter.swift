//
//  UndeadAttackBonusCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class UndeadfBuffCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool { true }
    override var cardIdToShowInUI: String? { CardIds.NonCollectible.Neutral.NerubianDeathswarmer }
    override var localizedName: String { String.localizedString("Counter_UndeadBuff", comment: "") }
    override var relatedCards: [String] { [] }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isBattlegroundsMatch() else { return false }
        return (attackCounter > 0 || healthCounter > 0) && game.player.board.contains { $0.card.isUndead() }
    }

    override func getCardsToDisplay() -> [String] {
        return [
            CardIds.NonCollectible.Neutral.NerubianDeathswarmer,
            CardIds.NonCollectible.Neutral.AnubarakNerubianKing,
            CardIds.NonCollectible.Neutral.DustboneDevastator,
            CardIds.NonCollectible.Neutral.Plaguerunner,
            CardIds.NonCollectible.Neutral.ChampionOfThePrimus,
            CardIds.NonCollectible.Neutral.Butchering,
            CardIds.NonCollectible.Neutral.ForsakenWeaver,
            CardIds.NonCollectible.Neutral.DustboneDevastator
        ]
    }

    override func valueToShow() -> String {
        return healthCounter > 0 ? "+\(attackCounter) / +\(healthCounter)" : "+\(attackCounter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }

        if tag == .zone,
           value == Zone.play.rawValue || (value == Zone.setaside.rawValue && prevValue == Zone.play.rawValue),
           entity.card.isUndead() {
            onCounterChanged()
        }

        if entity.card.id != CardIds.NonCollectible.Neutral.NerubianDeathswarmer_UndeadBonusAttackPlayerEnchantDnt {
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
