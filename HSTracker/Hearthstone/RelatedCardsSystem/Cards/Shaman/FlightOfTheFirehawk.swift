//
//  FlightOfTheFirehawk.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FlightOfTheFirehawk: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Shaman.FlightOfTheFirehawk
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion && !card.isEmptyRace())
    }
}
