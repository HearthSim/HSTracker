//
//  CardUtils.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardUtils {
    static func isCardFromFormat(card: Card, format: Format?) -> Bool {
        switch format {
        case .classic:
            return CardSet.classicSets().contains(card.set ?? .invalid)
        case .wild:
            return !CardSet.classicSets().contains(card.set ?? .invalid)
        case .standard:
            return !CardSet.wildSets().contains(card.set ?? .invalid) && !CardSet.classicSets().contains(card.set ?? .invalid)
        case .twist:
            return CardSet.twistSets().contains(card.set ?? .invalid)
        default:
            return true
        }
    }
    
    static func isCardFromPlayerClass(card: Card, playerClass: CardClass?, ignoreNeutral: Bool = false) -> Bool {
        return (card.playerClass == playerClass || card.getTouristVisitClass() == playerClass ||
             (!ignoreNeutral && card.playerClass == .neutral))
    }

    static func mayCardBeRelevant(card: Card, format: Format?, playerClass: CardClass?, ignoreNeutral: Bool = false) -> Bool {
        return isCardFromFormat(card: card, format: format) && isCardFromPlayerClass(card: card, playerClass: playerClass, ignoreNeutral: ignoreNeutral)
    }
        
    static func getProcessedCardFromCardId(_ cardId: String?, _ player: Player) -> Card? {
        guard let card = Cards.by(cardId: cardId) else { return nil }
        return card.handleZilliax3000(player: player)
    }

}

extension Card {
    func handleZilliax3000(player: Player) -> Card? {
        if id.starts(with: CardIds.Collectible.Neutral.ZilliaxDeluxe3000) {
            if let sideboard = player.playerSideboardsDict.first(where: { $0.ownerCardId == CardIds.Collectible.Neutral.ZilliaxDeluxe3000 }),
               sideboard.cards.count > 0 {
                let cosmetic = sideboard.cards.first { !$0.zilliaxCustomizableFunctionalModule }
                let modules = sideboard.cards.filter { $0.zilliaxCustomizableFunctionalModule }

                // Clone Zilliax with new cost, attack, health, and mechanics
                let newCard = cosmetic?.copy() ?? copy()
                var mechanics: [String] = []
                
                for module in modules where module.mechanics.count > 0 {
                    mechanics.append(contentsOf: module.mechanics)
                }
                
                newCard.mechanics = mechanics
                newCard.attack = modules.reduce(0) { $0 + $1.attack }
                newCard.health = modules.reduce(0) { $0 + $1.health }
                newCard.cost = modules.reduce(0) { $0 + $1.cost }
                
                return newCard
            }
        }
        
        return self
    }
}

extension Array where Element: Card {
    func filterCardsByFormat(format: Format?) -> [Card] {
        return filter { CardUtils.isCardFromFormat(card: $0, format: format) }
    }
    
    func filterCardsByPlayerClass(playerClass: CardClass?, ignoreNeutral: Bool = false) -> [Card] {
        return filter { CardUtils.isCardFromPlayerClass(card: $0, playerClass: playerClass, ignoreNeutral: ignoreNeutral) }
    }
}
