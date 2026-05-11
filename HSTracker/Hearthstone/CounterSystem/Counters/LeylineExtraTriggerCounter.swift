//
//  LeylineExtraTriggerCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class LeylineExtraTriggerCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Mage.SurgeNeedle
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Mage.SurgeNeedle,
            CardIds.Collectible.Mage.TheArcanomicon
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        return counter > 0
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        // Tag 4283 corresponds to Leyline Extra Triggers
        guard tag.rawValue == 4283 else { return }

        if value == 0 {
            return
        }

        let controller = entity[.controller]
        let isPlayerController = controller == game.player.id
        
        if isPlayerController == isPlayerCounter {
            counter = value
        }
    }
}
