//
//  AsteroidExtraDamageCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/30/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class AsteroidExtraDamageCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_AsteroidDamage", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.Asteroid
    }

    override var relatedCards: [String] {
        return []
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return !game.isBattlegroundsMatch() && counter > 0
    }

    override func getCardsToDisplay() -> [String] {
        return [CardIds.NonCollectible.Neutral.Asteroid]
    }

    override var isDisplayValueLong: Bool {
        return true
    }

    override func valueToShow() -> String {
        return String(format: String.localizedString("Counter_AsteroidDamage_Damage", comment: ""), NSNumber(value: 2 + counter))
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if entity.isControlled(by: game.player.id) == isPlayerCounter {
            if tag == .gametag_3559 {
                counter = value
            }
        }
    }
}
