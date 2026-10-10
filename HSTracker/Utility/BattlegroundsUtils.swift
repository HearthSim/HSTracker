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

    static func getBattlegroundsDeityDbfId(game: Entity?) -> Int? {
        guard let game = game else {
            return nil
        }
        let deityDbfId = game[.bacon_global_old_god_dbid]
        if deityDbfId > 0 {
            return deityDbfId
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
        BattlegroundsKeyword(locKey: "Battlegrounds_Browser_Filter_Lockbox", englishName: "Lockbox", mechanic: nil, requiredRace: .pirate)
    ]

    private static let availableRacesTimeout: TimeInterval = 15

    private static let pendingRacesWaitLock = NSLock()
    // HDT's _gameplayCancellation: bumped when gameplay is left, which ends
    // every wait still in flight instead of letting it run into the next game.
    private static var gameplayGeneration = 0
    private static var pendingRacesWait: (gameId: String, task: Task<[Race]?, Error>)?

    // The memory read can come up empty right after the game starts, so keep
    // trying for a while (nil if it keeps failing, CancellationError once the
    // game is over so callers can stop quietly). game.availableRaces caches
    // the result for the game, which reset() replaces along with its gameId.
    static func waitForAvailableRaces() async throws -> [Race]? {
        let game = AppDelegate.instance().coreManager.game
        let generation = pendingRacesWaitLock.withLock { gameplayGeneration }
        let gameId = game.gameId

        if game.isInMenu {
            throw CancellationError()
        }

        // another caller may have read them since the shared wait's last attempt
        if let races = game.availableRaces {
            return races
        }

        let task: Task<[Race]?, Error> = pendingRacesWaitLock.withLock {
            // a finished wait is not reused, so a caller after a timeout gets a fresh attempt
            if let pending = pendingRacesWait, pending.gameId == gameId {
                return pending.task
            }
            let task = Task<[Race]?, Error> {
                defer {
                    pendingRacesWaitLock.withLock {
                        if pendingRacesWait?.gameId == gameId {
                            pendingRacesWait = nil
                        }
                    }
                }
                return try await waitForAvailableRaces(
                    read: { game.availableRaces },
                    isSameGame: { isCurrentGame(gameId) && pendingRacesWaitLock.withLock { gameplayGeneration } == generation },
                    timeout: availableRacesTimeout,
                    initialDelay: 0.25)
            }
            pendingRacesWait = (gameId, task)
            return task
        }

        let races = try await task.value

        if !isCurrentGame(gameId) || pendingRacesWaitLock.withLock({ gameplayGeneration }) != generation {
            throw CancellationError()
        }

        return races
    }

    // leaving gameplay ends every wait still in flight, instead of letting them run into the next game
    static func cancelAvailableRacesWaits() {
        let cancelled: Task<[Race]?, Error>? = pendingRacesWaitLock.withLock {
            gameplayGeneration += 1
            let task = pendingRacesWait?.task
            pendingRacesWait = nil
            return task
        }
        cancelled?.cancel()
    }

    private static func isCurrentGame(_ gameId: String) -> Bool {
        let game = AppDelegate.instance().coreManager.game
        return !game.isInMenu && game.gameId == gameId
    }

    static func waitForAvailableRaces(read: () -> [Race]?, isSameGame: () -> Bool, timeout: TimeInterval, initialDelay: TimeInterval) async throws -> [Race]? {
        let start = Date()
        var delay = initialDelay
        let maxDelay: TimeInterval = 2
        while true {
            try Task.checkCancellation()
            if let races = read() {
                return races
            }
            if !isSameGame() {
                throw CancellationError()
            }
            if Date().timeIntervalSince(start) >= timeout {
                return nil
            }
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay = min(delay * 2, maxDelay)
        }
    }

    static func getAvailableKeywords(availableRaces: [Race]?) -> [BattlegroundsKeyword] {
        guard let availableRaces else {
            return availableKeywords
        }
        return availableKeywords.filter { keyword in
            guard let required = keyword.requiredRace else { return true }
            return availableRaces.contains(required)
        }
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
