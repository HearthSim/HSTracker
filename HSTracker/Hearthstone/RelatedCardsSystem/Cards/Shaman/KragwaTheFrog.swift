//
//  KragwaTheFrog.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class KragwaTheFrog: ICardWithRelatedCards {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Shaman.KragwaTheFrog
    }
    
    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
    
    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedLastTurn
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0?.type == .spell }
            .sorted { ($0?.cost ?? 0) > ($1?.cost ?? 0) }
    }
}

public class KragwaTheFrogCore: KragwaTheFrog {
    
    public required init() {
        super.init()
    }
    
    public override func getCardId() -> String {
        return CardIds.Collectible.Shaman.KragwaTheFrogCore
    }
}
