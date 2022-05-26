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
    
    static func getOriginalHeroId(heroId: String) -> String {
        if let mapped = BattlegroundsUtils.transformableHeroCardidTable[heroId] {
            return mapped
        }
        return heroId
    }
}
