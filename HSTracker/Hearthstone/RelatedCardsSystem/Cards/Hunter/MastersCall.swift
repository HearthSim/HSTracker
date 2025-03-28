//
//  MastersCall.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable inclusive_language
class MastersCall: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.MastersCall
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isBeast(), card.type == .minion)
    }
}

class MastersCallCore: MastersCall {
    override func getCardId() -> String {
        return CardIds.Collectible.Hunter.MastersCallCore
    }
}
//swiftlint:enable inclusive_language

