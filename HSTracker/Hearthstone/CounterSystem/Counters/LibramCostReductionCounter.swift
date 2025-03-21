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
            CardIds.Collectible.Paladin.LibramOfWisdom,
            CardIds.Collectible.Paladin.LibramOfClarity,
            CardIds.Collectible.Paladin.LibramOfDivinity,
            CardIds.Collectible.Paladin.LibramOfJustice,
            CardIds.Collectible.Paladin.LibramOfFaith,
            CardIds.Collectible.Paladin.LibramOfJudgment,
            CardIds.Collectible.Paladin.LibramOfHope
        ]
    }
    
    private static let enchantLibramDict: [String: Int] = [
        CardIds.NonCollectible.Neutral.AldorAttendant_AldorAttendantEnchantment: 1,
        CardIds.NonCollectible.Neutral.AldorTruthseeker_AldorTruthseekerEnchantment: 2,
        CardIds.NonCollectible.Paladin.InterstellarStarslicer_InterstellarLibramEnchantmentEnchantment: 1
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
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
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
