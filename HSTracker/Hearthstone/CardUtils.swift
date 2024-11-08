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
}

extension Array where Element: Card {
    func filterCardsByFormat(format: Format?) -> [Card] {
        return filter { CardUtils.isCardFromFormat(card: $0, format: format) }
    }
    
    func filterCardsByPlayerClass(playerClass: CardClass?, ignoreNeutral: Bool = false) -> [Card] {
        return filter { CardUtils.isCardFromPlayerClass(card: $0, playerClass: playerClass, ignoreNeutral: ignoreNeutral) }
    }
}
