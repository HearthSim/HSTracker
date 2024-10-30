//
//  LibramCostReductionCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class LibramCostReductionCounter: NumericCounter {
    
    override var localizedName: String {
        return String.localizedString("Counter_LibramCostReduction", comment: "")
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Paladin.AldorAttendant
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Paladin.AldorAttendant,
            CardIds.Collectible.Paladin.AldorTruthseeker
        ]
    }
    
    private static let enchantLibramDict: [String: Int] = [
        CardIds.NonCollectible.Neutral.AldorAttendant_AldorAttendantEnchantment: 1,
        CardIds.NonCollectible.Neutral.AldorTruthseeker_AldorTruthseekerEnchantment: 2
    ]

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        }
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.playerClass)
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag == .zone, value == Zone.play.rawValue {
            if let enchantValue = Self.enchantLibramDict[entity.card.id] {
                let controller = entity[.controller]
                
                if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
                    counter += enchantValue
                }
            }
        }
    }
}
