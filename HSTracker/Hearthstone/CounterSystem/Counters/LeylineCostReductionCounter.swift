//
//  LeylineCostReductionCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class LeylineCostReductionCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Mage.LeyWalker
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Mage.LeyWalker,
            CardIds.Collectible.Mage.TheArcanomicon
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isTraditionalHearthstoneMatch && counter > 0
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        guard tag == .zone else { return }
        guard value == Zone.play.rawValue else { return }

        if entity.card.id == CardIds.NonCollectible.Mage.LeyWalker_UnblockLeylineToken {
            counter += 1
        }
    }
}
