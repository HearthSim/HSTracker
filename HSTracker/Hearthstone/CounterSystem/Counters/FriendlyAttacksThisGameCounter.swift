//
//  FriendlyAttacksThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class FriendlyAttacksThisGameCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Shaman.MuradinsLastStand
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Shaman.MuradinsLastStand]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        return isPlayerCounter && inPlayerDeckOrKnown(cardIds: relatedCards)
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        // C# uses Counter_AnimalCompanionCost as a generic localized string with a placeholder
        let remainingAttacks = max(9 - counter, 0)
        return String(format: String.localizedString("Counter_MuradinLastStand", comment: ""), "(\remainingAttacks)")
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        guard tag == .attacking else { return }
        
        // In Hearthstone logs, value 1 means attacking, value 0 means stop attacking
        if value != 0 {
            counter += 1
        }
    }
}
