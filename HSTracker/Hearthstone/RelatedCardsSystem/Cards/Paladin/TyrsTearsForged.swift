//
//  TyrsTearsForged.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

class TyrsTearsForged: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.NonCollectible.Paladin.TyrsTears
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.deadMinionsCards
            .compactMap { CardUtils.getProcessedCardFromEntity($0, player) }
            .unique()
            .filter { $0.isClass(cardClass: player.currentClass ?? .invalid) }
            .sorted { $0.cost < $1.cost }
    }

    required init() {
    }
}
