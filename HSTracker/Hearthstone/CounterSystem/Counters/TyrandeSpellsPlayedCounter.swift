//
//  TyrandeSpellsPlayedCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TyrandeSpellsPlayedCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Priest.Tyrande
    }

    override var relatedCards: [String] {
        return []
    }

    var tyrandeEnchantmentsInPlay: Int = 0

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isTraditionalHearthstoneMatch && tyrandeEnchantmentsInPlay > 0
    }

    override func getCardsToDisplay() -> [String] {
        return [ CardIds.Collectible.Priest.Tyrande ]
    }

    override func valueToShow() -> String {
        return "\(counter) / 3"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag == .zone,
           entity.card.id == CardIds.NonCollectible.Priest.Tyrande_PullOfTheMoonEnchantment,
           entity[.controller] == (isPlayerCounter ? game.player.id : game.opponent.id) {
            if value == Zone.play.rawValue {
                tyrandeEnchantmentsInPlay += 1
                counter = 0
                onCounterChanged()
            } else if value == Zone.graveyard.rawValue {
                tyrandeEnchantmentsInPlay -= 1
                onCounterChanged()
            }
        }

        guard entity.card.id == CardIds.NonCollectible.Priest.Tyrande_PullOfTheMoonEnchantment else { return }
        guard tag == .tag_script_data_num_1 else { return }

        let controller = entity[.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter = value
        }
    }
}
