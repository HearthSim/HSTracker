//
//  Zuljin.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/5/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

public class Zuljin: ICardWithRelatedCards {

    public required init() {}

    public func getCardId() -> String {
        return CardIds.Collectible.Hunter.Zuljin
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.spellsPlayedCards
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .sorted { $0.cost > $1.cost }
    }
}
