//
//  AvianaElunesChosenTurnCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class AvianaElunesChosenTurnCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Priest.AvianaElunesChosen
    }

    override var relatedCards: [String] {
        return []
    }

    var avianaEnchantmentsInPlay: Int = 0

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isTraditionalHearthstoneMatch && avianaEnchantmentsInPlay > 0
    }

    override func getCardsToDisplay() -> [String] {
        return [CardIds.Collectible.Priest.AvianaElunesChosen]
    }

    override func valueToShow() -> String {
        return "\(counter) / 3"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag == .zone,
           value == Zone.play.rawValue,
           entity.card.id == CardIds.NonCollectible.Priest.AvianaElunesChosen_MoonCycleToken,
           entity[.controller] == (isPlayerCounter ? game.player.id : game.opponent.id) {
            avianaEnchantmentsInPlay += 1
            onCounterChanged()
        }

        // we only need the counter to work once because once the countdown is over the effect is permanent
        guard avianaEnchantmentsInPlay < 2 else { return }

        if entity.card.id != CardIds.NonCollectible.Priest.AvianaElunesChosen_MoonCycleToken {
            return
        }

        if tag != .tag_script_data_num_1 {
            return
        }

        let controller = entity[.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter = 3 - value
        }
    }
}
