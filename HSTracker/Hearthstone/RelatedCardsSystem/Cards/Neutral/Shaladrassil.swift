//
//  Shaladrassil.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class Shaladrassil: ICardWithRelatedCards {
    required init() {
        
    }
    
    private let dreamCards: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.DreamCards.Dream),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.Nightmare),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.YseraAwakens),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.LaughingSister),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.EmeraldDrake),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.Shaladrassil_CorruptedDreamToken),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.Shaladrassil_CorruptedNightmareToken),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.Shaladrassil_CorruptedAwakeningToken),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.Shaladrassil_CorruptedLaughingSisterToken),
        Cards.any(byId: CardIds.NonCollectible.DreamCards.Shaladrassil_CorruptedDrakeToken)
    ]

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.Shaladrassil
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return dreamCards
    }
}
