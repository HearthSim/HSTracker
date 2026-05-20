//
//  DeathwingDiscount.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class DeathwingDiscount: NumericCounter {

    override var localizedName: String {
        return String.localizedString("Counter_DeathwingDiscount", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Invalid.DeathwingWorldbreakerHeroic
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Invalid.Ultraxion,
            CardIds.Collectible.Invalid.DeathwingWorldbreakerHeroic
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        return counter != 0
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.cardId != CardIds.NonCollectible.Neutral.Ultraxion_UltraxionHeraldedEnchantment {
            return
        }

        if tag != .tag_script_data_num_1 {
            return
        }

        if value == 0 {
            return
        }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter -= value
        }
    }
}
