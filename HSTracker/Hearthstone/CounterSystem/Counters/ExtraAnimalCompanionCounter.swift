//
//  ExtraAnimalCompanionCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class ExtraAnimalCompanionCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Hunter.TalyaEarthstrider
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Hunter.TalyaEarthstrider]
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

        let controller = entity[.controller]
        let isPlayerController = controller == game.player.id
        guard isPlayerController == isPlayerCounter else { return }

        // Tag 4629 represents the specific counter for Animal Companion logic
        guard tag.rawValue == 4629 else { return }

        if value == 0 {
            return
        }

        counter = value
    }
}
