//
//  BattlegroundsUtils.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/16/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsUtils {
    private static let transformableHeroCardidTable = [
        CardIds.NonCollectible.Neutral.ArannaStarseeker_ArannaUnleashedTokenTavernBrawl: CardIds.NonCollectible.Neutral.ArannaStarseekerTavernBrawl1,
        CardIds.NonCollectible.Neutral.QueenAzshara_NagaQueenAzsharaToken: CardIds.NonCollectible.Neutral.QueenAzsharaBATTLEGROUNDS ]
    
    static func getOriginalHeroId(heroId: String, mapKelthuzad: Bool = false) -> String {
        var result = heroId
        if mapKelthuzad && heroId == "TB_BaconShop_HERO_KelThuzad" {
            let game = AppDelegate.instance().coreManager.game
            
            if let currentPlayer = game.entities.values.first(where: { x in x.has(tag: GameTag.next_opponent_player_id) }) {
                if let nextOpponent = game.entities.values.first(where: { x in x[GameTag.player_id] == currentPlayer[GameTag.next_opponent_player_id] }), nextOpponent.health <= 0 {
                    result = nextOpponent.cardId
                    logger.debug("Kel'Thuzad corrected id is \(result)")
                }
            }
        }

        if let mapped = BattlegroundsUtils.transformableHeroCardidTable[result] {
            return mapped
        }
        return result
    }
}
