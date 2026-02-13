//
//  VolumizerBuffCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class VolumizerBuffCounter: StatsCounter {

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.AutoAccelerator_RedVolumizerToken1
    }
    
    override var localizedName: String {
        return String.localizedString("Counter_VolumizerBuff", comment: "")
    }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.AutoAccelerator_GreenVolumizerToken1,
            CardIds.NonCollectible.Neutral.AutoAccelerator_RedVolumizerToken1,
            CardIds.NonCollectible.Neutral.AutoAccelerator_BlueVolumizerToken1,
            CardIds.NonCollectible.Neutral.AutoAccelerator,
            CardIds.NonCollectible.Neutral.ConveyorConstruct,
            CardIds.NonCollectible.Neutral.ApexisGuardian
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

        if entity.card.id != CardIds.NonCollectible.Neutral.AutoAccelerator_VolumizedEnchantment {
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
