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
    
    static func getAvailableTiers(anomalyCardId: String?) -> [Int] {
        switch anomalyCardId {
        case CardIds.NonCollectible.Neutral.BigLeague:
            return [3, 4, 5, 6]
        case CardIds.NonCollectible.Neutral.HowToEven:
            return [2, 4, 6]
        case CardIds.NonCollectible.Neutral.LittleLeague:
            return [1, 2, 3, 4]
        case CardIds.Invalid.SecretsOfNorgannon:
            return [1, 2, 3, 4, 5, 6, 7]
        case CardIds.NonCollectible.Neutral.ValuationInflation:
            return [2, 3, 4, 5, 6]
        case CardIds.NonCollectible.Neutral.WhatAreTheOdds:
            return [1, 3, 5]
        default:
            return [1, 2, 3, 4, 5, 6]
        }
    }
    
    static func getBattlegroundsAnomalyDbfId(game: Entity?) -> Int? {
        guard let game = game else {
            return nil
        }
        let anomalyDbfId = game[.bacon_global_anomaly_dbid]
        if anomalyDbfId > 0 {
            return anomalyDbfId
        }
        return nil
    }
        
    // Mirrors HDT's BattlegroundsUtils._availableKeywords, in the same order -
    // the Mechanics list in the extra-filters panel renders it top to bottom.
    // Every englishName is verified against HDT-Localization's Strings.resx;
    // note "End Of Turn" and "Start Of Combat" capitalise the Of, which is why
    // BattlegroundsKeyword matches card text case-insensitively.
    // Every entry is a TagKeyword (tag OR English mention) except Lockbox, which
    // the client never tags, so it matches on the mention alone.
    private static let availableKeywords: [BattlegroundsKeyword] = [
        BattlegroundsKeyword(locKey: "GameTag_Battlecry", englishName: "Battlecry", mechanic: "BATTLECRY"),
        BattlegroundsKeyword(locKey: "GameTag_Deathrattle", englishName: "Deathrattle", mechanic: "DEATHRATTLE"),
        BattlegroundsKeyword(locKey: "GameTag_BGAvenge", englishName: "Avenge", mechanic: "AVENGE"),
        BattlegroundsKeyword(locKey: "GameTag_BGRally", englishName: "Rally", mechanic: "BACON_RALLY"),
        BattlegroundsKeyword(locKey: "GameTag_DivineShield", englishName: "Divine Shield", mechanic: "DIVINE_SHIELD"),
        BattlegroundsKeyword(locKey: "GameTag_Taunt", englishName: "Taunt", mechanic: "TAUNT"),
        BattlegroundsKeyword(locKey: "GameTag_EndOfTurn", englishName: "End Of Turn", mechanic: "END_OF_TURN_TRIGGER"),
        BattlegroundsKeyword(locKey: "GameTag_StartOfCombat", englishName: "Start Of Combat", mechanic: "START_OF_COMBAT"),
        BattlegroundsKeyword(locKey: "GameTag_Reborn", englishName: "Reborn", mechanic: "REBORN"),
        BattlegroundsKeyword(locKey: "GameTag_ChooseOne", englishName: "Choose One", mechanic: "CHOOSE_ONE"),
        BattlegroundsKeyword(locKey: "GameTag_Modular", englishName: "Magnetic", mechanic: "MODULAR"),
        BattlegroundsKeyword(locKey: "GameTag_Venomous", englishName: "Venomous", mechanic: "VENOMOUS"),
        BattlegroundsKeyword(locKey: "GameTag_BGActivate", englishName: "Activate", mechanic: "BACON_ACTIVATE_TOOLTIP"),
        BattlegroundsKeyword(locKey: "Battlegrounds_Browser_Filter_Lockbox", englishName: "Lockbox", mechanic: nil)
    ]

    static func getAvailableKeywords() -> [BattlegroundsKeyword] {
        return availableKeywords
    }

    static let tavernSpellRaceMapping: [String: Race] = [
        // Scavenge for Parts
        "BG28_600": .mechanical,
        // Cloning Conch
        "BG28_601": .murloc,
        // Guzzle the Goop
        "BG28_602": .dragon,
        // Boon of Beetles
        "BG28_603": .beast,
        // Butchering
        "BG28_604": .undead,
        // Suspicious Stimulant
        "BG28_605": .elemental,
        // Suspicious Stimulant
        "BG28_606": .naga,
        // Corrupted Cupcakes
        "BG28_607": .demon,
        // Plunder Seeker
        "BG28_609": .pirate,
        // Gem Confiscation
        "BG28_698": .quilboar
    ]
}
