//
//  BeetlesSizeCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BeetlesSizeCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool { true }
    override var cardIdToShowInUI: String? { CardIds.NonCollectible.Neutral.BoonofBeetles_BeetleToken1 }
    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.BoonofBeetles_BeetleToken1,
            CardIds.NonCollectible.Neutral.BuzzingVermin,
            CardIds.NonCollectible.Neutral.ForestRover,
            CardIds.NonCollectible.Neutral.TurquoiseSkitterer,
            CardIds.NonCollectible.Neutral.RunedProgenitor,
            CardIds.NonCollectible.Neutral.NestSwarmer
        ]
    }

    private let beetleBaseAttack: Int
    private let beetleBaseHealth: Int

    required init(controlledByPlayer: Bool, game: Game) {
        let beetleCard = Cards.by(cardId: CardIds.NonCollectible.Neutral.BoonofBeetles_BeetleToken1)
        self.beetleBaseAttack = beetleCard?.attack ?? 1
        self.beetleBaseHealth = beetleCard?.health ?? 1
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isBattlegroundsMatch() else { return false }
        return (attackCounter > beetleBaseAttack || healthCounter > beetleBaseHealth)
            && game.player.board.contains { entity in
                relatedCards.contains(entity.cardId)
            }
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(attackCounter) / \(healthCounter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }

        if tag == .zone,
           value == Zone.play.rawValue || (value == Zone.setaside.rawValue && prevValue == Zone.play.rawValue),
           relatedCards.contains(entity.cardId) {
            onCounterChanged()
        }

        guard entity.card.id == CardIds.NonCollectible.Neutral.RunedProgenitor_BeetleArmyPlayerEnchantDnt else { return }

        if tag == .tag_script_data_num_1 {
            attackCounter = beetleBaseAttack + value
        }

        if tag == .tag_script_data_num_2 {
            healthCounter = beetleBaseHealth + value
        }
    }
}
