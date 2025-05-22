//
//  HopefulDryad.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HopefulDryad: ICardWithRelatedCards {
    private let dreamCards: [Card?] = [
        Cards.by(cardId: CardIds.NonCollectible.DreamCards.Dream),
        Cards.by(cardId: CardIds.NonCollectible.DreamCards.Nightmare),
        Cards.by(cardId: CardIds.NonCollectible.DreamCards.YseraAwakens),
        Cards.by(cardId: CardIds.NonCollectible.DreamCards.LaughingSister),
        Cards.by(cardId: CardIds.NonCollectible.DreamCards.EmeraldDrake)
    ]
    
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.HopefulDryad
    }
    
    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
    
    func getRelatedCards(player: Player) -> [Card?] {
        return dreamCards
    }
}
