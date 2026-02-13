//
//  BloodGemBarrageBuffCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class BloodGemBarrageBuffCounter: StatsCounter {

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    public override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.BloodGemBarrage
    }

    public override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.BloodGemBarrage,
            CardIds.NonCollectible.Neutral.BriarbackDrummer,
            CardIds.NonCollectible.Neutral.RazorfenFlapper
        ]
    }

    public override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && (attackCounter > 0 || healthCounter > 0)
    }

    public override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    public override func valueToShow() -> String {
        return "+\(attackCounter) / +\(healthCounter)"
    }

    public override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isBattlegroundsMatch() {
            return
        }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if entity.card.id != CardIds.NonCollectible.Neutral.BloodGemBarrage_BloodGemBarragePlayerEnchDntEnchantment {
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
