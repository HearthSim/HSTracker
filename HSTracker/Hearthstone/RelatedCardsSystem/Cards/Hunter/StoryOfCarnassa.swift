//
//  StoryOfCarnassa.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/8/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class StoryOfCarnassa: ICardWithRelatedCards {
    required init() {
    
    }
    
    private let token: [Card?] = [
        Cards.by(cardId: CardIds.NonCollectible.Hunter.TheMarshQueen_CarnassasBroodToken)
    ]

    func getCardId() -> String {
        CardIds.Collectible.Hunter.StoryOfCarnassa
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        token
    }
}
