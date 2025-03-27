//
//  MastersCall.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class MastersCall: ICardWithHighlight {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.MastersCall
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isBeast(), card.type == .minion)
    }
}

class MastersCallCore: MastersCall {
    override func getCardId() -> String {
        return CardIds.Collectible.Hunter.MastersCallCore
    }
}

