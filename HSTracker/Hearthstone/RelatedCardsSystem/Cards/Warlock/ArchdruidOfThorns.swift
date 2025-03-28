//
//  ArchdruidOfThorns.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class ArchdruidOfThorns: ICardWithRelatedCards {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Warlock.ArchdruidOfThorns
    }
    
    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
    
    func getRelatedCards(player: Player) -> [Card?] {
        return player.deadMinionsCards
            .filter { $0.info.turn == AppDelegate.instance().coreManager.game.turnNumber() }
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0?.hasDeathrattle() == true }
            .sorted { ($0?.cost ?? 0) > ($1?.cost ?? 0) }
    }
}
