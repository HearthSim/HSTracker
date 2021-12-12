//
//  BobsBuddyInvoker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/14/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import PromiseKit
import AppCenterAnalytics

class BobsBuddyInvoker {
    
    let Iterations: Int = 10_000
    let MaxTime: Int = 1_500
    let MaxTimeForComplexBoards = 3_000
    let HeroPowerTriggerTimeout = 5000
    let StateChangeDelay = 500
    let LichKingDelay = 2000
    
    static let cardIdsWithoutPremiumImplementation: [String] = MinionFactoryProxy.getCardIdsWithoutPremiumImplementations()
    
    static let cardIdsWithCleave: [String] = MinionFactoryProxy.getCardIdsWithCleave()
    
    static let cardIdsWithMegaWindfury: [String] = MinionFactoryProxy.getCardIdsWithMegaWindfury()
    
    var state: BobsBuddyState = .initial
    
    var errorState: BobsBuddyErrorState = .none
    
    var input: TestInputProxy?
    
    private var currentOpponentMinions: [Int: MinionProxy] = [:]
    
    private var currentOpponentSecrets: [Entity] = []
    
    var minionHeroPowerTrigger: MinionHeroPowerTrigger?
    
    private let turn: Int
    
    private final let LichKingHeroPowerId = CardIds.NonCollectible.Neutral.RebornRitesTavernBrawl
    private final let LichKingHeroPowerEnchantmentId = CardIds.NonCollectible.Neutral.RebornRites_RebornRiteEnchantmentTavernBrawl
    private final let canRemoveLichKing: Bool = RemoteConfig.data?.bobs_buddy?.can_remove_lich_king ?? false
    
    private var runSimulationAfterCombat: Bool {
        return currentOpponentSecrets.count > 0
    }
    
    let queue = DispatchQueue(label: "BobsBuddy", qos: .userInitiated)
    
    private static var _instance: BobsBuddyInvoker?
    
    private static let bobsBuddyDisplay = AppDelegate.instance().coreManager.game.windowManager.bobsBuddyPanel
    
    private init(turn: Int) {
        self.turn = turn
    }
    
    static func instance(turn: Int) -> BobsBuddyInvoker {
        if let inst = _instance {
            if inst.turn == turn {
                return inst
            }
        }
        _instance = BobsBuddyInvoker(turn: turn)
        return _instance!
    }
    
    func shouldRun() -> Bool {
        if !AppDelegate.instance().coreManager.game.isBattlegroundsMatch() {
            return false
        }
        return true
    }
    
    func setMinionReborn(entityId: Int) {
        if let rebornMinion = currentOpponentMinions[entityId] {
            let opaque = mono_thread_attach(MonoHelper._monoInstance)
            
            defer {
                mono_thread_detach(opaque)
            }

            rebornMinion.setReceivesLichKingPower(power: true)
        }
    }
    
    func startCombat() {
        if !shouldRun() {
            return
        }
        if state == .combat {
            logger.debug("Already in \(state) state. Exiting")
            return
        }
        logger.info("State is now combat")
        state = .combat
        let opaque = mono_thread_attach(MonoHelper._monoInstance)
        
        defer {
            mono_thread_detach(opaque)
        }

        minionHeroPowerTrigger = nil
        
        snapshotBoardState()
        
        Thread.sleep(forTimeInterval: Double(StateChangeDelay) / 1_000.0)
        
        if state != .combat {
            logger.debug("No longer in combat: State=\(state). Exiting")
            return
        }
        if hasErrorState() {
            return
        }
        
        logger.debug("Setting UI state to combat...")
        if runSimulationAfterCombat {
            state = .combatWithoutSimulation
            BobsBuddyInvoker.bobsBuddyDisplay.setState(st: .combatWithoutSimulation)
        } else {
            BobsBuddyInvoker.bobsBuddyDisplay.setState(st: .combat)
        }
        
        if let mhpt = minionHeroPowerTrigger, canRemoveLichKing {
            let minion = mhpt.minion
            let start = DispatchTime.now()
            logger.debug("Waiting for hero power \(mhpt.heroPowerId) trigger for \(minion.getMinionName())...")
            
            let result = mhpt.semaphore.wait(timeout: .now() + .milliseconds(HeroPowerTriggerTimeout))
            
            let duration = (DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            
            if result == .timedOut {
                logger.debug("Found no hero power trigger after \(duration)ms. Resetting receivedHeroPower on \(minion.getMinionName())")
                minion.setReceivesLichKingPower(power: false)
            } else {
                logger.debug("Found hero power trigger for \(minion.getMinionName()) after \(duration)ms")
            }
        }
        
        let game = AppDelegate.instance().coreManager.game
        if game.opponent.board.any({ x in
            x.cardId == LichKingHeroPowerId || x.cardId == LichKingHeroPowerEnchantmentId
        }) {
            usleep(useconds_t(LichKingDelay * 1000))
        }
        
        if !runSimulationAfterCombat {
            _ = runAndDisplaySimulationAsync().catch({ error in
            logger.error("Error running simulation: \(error.localizedDescription)")
            BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .failedToLoad)
            Analytics.trackEvent("runSimulation failed", withProperties: [ "error": error.localizedDescription])
            })
        }
    }
    
    func runAndDisplaySimulationAsync() -> Promise<Bool> {
        return Promise<Bool> { seal in
            currentOpponentMinions.removeAll()
            logger.debug("Running simulation...")
            BobsBuddyInvoker.bobsBuddyDisplay.hidePercentagesShowSpinners()
            _ = runSimulation().done { (result) in
                guard let top = result else {
                    logger.debug("Simulation returned no result. Exiting")
                    seal.fulfill(false)
                    return
                }
                let opaque = mono_thread_attach(MonoHelper._monoInstance)
                
                defer {
                    mono_thread_detach(opaque)
                }

                // Add enum for exit conditions
                if top.getSimulationCount() <= 500 && top.getMyExitCondition() ==  0 {
                    logger.debug("Could not perform enough simulations. Displaying error state and exiting.")
                    self.errorState = .notEnoughData
                    BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .notEnoughData)
                } else {
                    logger.debug("Displaying simulation results")
                    let winRate = top.getWinRate()
                    let tieRate = top.getTieRate()
                    let lossRate = top.getLossRate()
                    let myDeathRate = top.getMyDeathRate()
                    let theirDeathRate = top.getTheirDeathRate()
                    let possibleResults = top.getResultDamage()
                    
                    BobsBuddyInvoker.bobsBuddyDisplay.showCompletedSimulation(winRate: winRate, tieRate: tieRate, lossRate: lossRate, playerLethal: theirDeathRate, opponentLethal: myDeathRate, possibleResults: possibleResults)
                }
                seal.fulfill(true)
            }.catch({ error in
                logger.error("Error running simulation: \(error.localizedDescription)")
                BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .failedToLoad)
                Analytics.trackEvent("runSimulation failed", withProperties: [ "error": error.localizedDescription])
                seal.fulfill(false)
            })
        }
    }
    
    func runSimulation() -> Promise<TestOutputProxy?> {
        logger.info("Starting simulation")
        return Promise<TestOutputProxy?> { seal in
            queue.async {
                let opaque = mono_thread_attach(MonoHelper._monoInstance)
                
                var result: TestOutputProxy?
                
                if let inp = self.input {
                    if self.runSimulationAfterCombat {
                        let secrets: [Int] = self.currentOpponentSecrets.map({ $0.card.dbfId })
                        let opponentSecrets = inp.getOpponentSecrets()
                        for i in 0..<secrets.count {
                            inp.addSecretFromDbfid(id: Int32(secrets[i]), target: opponentSecrets)
                        }
                        logger.debug("Set opponent to Akazamarak with \(secrets.count) secrets.")
                    }
                    logger.debug("----- Simulation Input -----")
                    let str = inp.unitestCopyableVersion()
                    
                    logger.debug(str)
                    logger.debug("----- End of Input -----")
                    
                    let tc = ProcessInfo.processInfo.activeProcessorCount / 2
                    let simulator = SimulationRunnerProxy()
                    
                    let ps = inp.getPlayerSide()
                    let os = inp.getOpponentSide()
                    let at = (MonoHelper.listCount(obj: ps) > 6 || MonoHelper.listCount(obj: os) > 6) ? self.MaxTimeForComplexBoards : self.MaxTime
                    
                    logger.debug("Running simulations with MaxIterations=\(self.Iterations) and ThreadCount=\(tc)...")

                    let start = DispatchTime.now()
                    
                    let task = simulator.simulateMultiThreaded(input: inp, maxIterations: self.Iterations, threadCount: tc, maxDuration: at)
                    
                    let tinst = task.get()
                    let c = mono_object_get_class(tinst)
                    let cp = mono_class_get_parent(c)

                    let mw = mono_class_get_method_from_name(cp, "Wait", 0)
                    
                    _ = mono_runtime_invoke(mw, tinst, nil, nil)
                    
                    let mr = mono_class_get_method_from_name(c, "get_Result", 0)
                    let output = mono_runtime_invoke(mr, tinst, nil, nil)
                    
                    let top = TestOutputProxy(obj: output)
                    
                    let ellapsed = (DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                    
                    logger.debug("----- Simulation Output -----")
                    logger.debug("Duration=\(ellapsed)ms, ExitCondition=\(top.getMyExitCondition()), Iterations = \(top.getSimulationCount())")
                    logger.debug("WinRate=\(top.getWinRate() * 100)% (Lethal=\(top.getTheirDeathRate() * 100)%), TieRate=\(top.getTieRate() * 100)%, LossRate=\(top.getLossRate() * 100)% (Lethal=\(top.getMyDeathRate() * 100)%)")
                    logger.debug("----- End of Output -----")
                    
                    result = top
                } else {
                    logger.error("No input")
                }
                
                mono_thread_detach(opaque)
                seal.fulfill(result)
            }
        }
    }
    
    func startShopping() {
        if state == .shopping {
            logger.debug("Already in shopping state. Exiting")
            return
        }
        state = .shopping
        BobsBuddyInvoker.bobsBuddyDisplay.setState(st: .shopping)
        if !runSimulationAfterCombat {
            logger.debug("Setting UI state to shopping")
        } else {
            _ = runAndDisplaySimulationAsync().done { _ in }.catch { error in
                logger.error(error)
            }
        }
    }
    
    func hasErrorState() -> Bool {
        if errorState == .none {
            return false
        }
        BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: errorState)
        logger.debug("ErrorState=\(errorState)")
        return true
    }
    
    func heroPowerTriggered(heroPowerId: String) {
        if let mht = minionHeroPowerTrigger {
            if mht.heroPowerId == heroPowerId {
                mht.semaphore.signal()
            }
        }
    }
    
    func isUnknownCard(e: Entity?) -> Bool {
        return e?.card.id == "unknown"
    }
    
    func heroPowerUsed(heroPower: Entity?) -> Bool {
        return (heroPower?.has(tag: GameTag.exhausted) ?? false || heroPower?.has(tag: GameTag.bacon_hero_power_activated) ?? false)
    }
    
    static func getOrderedMinions(board: [Entity]) -> [Entity] {
        // swiftlint:disable force_cast
        return board.filter({ $0.isMinion }).map({ $0.copy() as! Entity }).sorted(by: { $0[GameTag.zone_position] < $1[GameTag.zone_position]})
        // swiftlint:enable force_cast
    }
    
    static func getMinionFromEntity(ent: Entity, attachedEntities: [Entity]) -> MinionProxy {
        let minion = MinionFactoryProxy.getMinionFromCardid(id: ent.cardId)
        
        minion.setBaseAttack(attack: Int32(ent[GameTag.atk]))
        minion.setBaseHealth(health: Int32(ent[GameTag.health]))
        minion.setTaunt(taunt: ent.has(tag: GameTag.taunt))
        minion.setDiv(div: ent.has(tag: GameTag.divine_shield))
        if cardIdsWithCleave.contains(ent.cardId) {
            minion.setCleave(cleave: true)
        }
        minion.setPoisonous(poisonous: ent.has(tag: GameTag.poisonous))
        minion.setWindfury(windfury: ent.has(tag: GameTag.windfury))
        minion.setMegaWindfury(megaWindfury: ent.has(tag: GameTag.mega_windfury) || cardIdsWithMegaWindfury.contains(ent.cardId))
        
        let golden = ent.has(tag: GameTag.premium)
        minion.setGolden(golden: golden)
        minion.setTier(tier: Int32(ent[GameTag.tech_level]))
        minion.setReborn(reborn: ent.has(tag: GameTag.reborn))
        
        if golden && (BobsBuddyInvoker.cardIdsWithoutPremiumImplementation.firstIndex(of: ent.cardId) != nil) {
            minion.setVanillaHealth(health: minion.getVanillaHealth() * 2)
        }
        
        minion.setMechDeathCount(count: Int32(attachedEntities.filter({ $0.cardId == CardIds.NonCollectible.Neutral.ReplicatingMenace_ReplicatingMenaceEnchantment }).count))
        minion.setMechDeathCountGold(count: Int32(attachedEntities.filter({ $0.cardId == CardIds.NonCollectible.Neutral.ReplicatingMenace_ReplicatingMenaceEnchantmentTavernBrawl }).count))
        minion.setPlantDeathCount(count: Int32(attachedEntities.filter({ $0.cardId == CardIds.NonCollectible.Neutral.LivingSporesToken2 }).count))
        
        if attachedEntities.any({ $0.cardId == CardIds.NonCollectible.Neutral.RebornRites_RebornRiteEnchantmentTavernBrawl }) {
            minion.setReceivesLichKingPower(power: true)
        }
        
        minion.setSneedsHeroCount(count: Int32(attachedEntities.filter { x in x.cardId == CardIds.NonCollectible.Neutral.Sneed_Replicate}.count))
        
        minion.setGameId(id: Int32(ent.id))
        return minion
    }
    
    static func getAttachedEntities(game: Game, entityId: Int) -> [Entity] {
        // swiftlint:disable force_cast
        return game.entities.values.filter({ $0.isAttachedTo(entityId: entityId) && ($0.isInPlay || $0.isInSetAside || $0.isInGraveyard) }).map({ $0.copy() as! Entity })
        // swiftlint:enable force_cast
    }

    func snapshotBoardState() {
        let game = AppDelegate.instance().coreManager.game
        
        let simulator = SimulatorProxy()
        let input = TestInputProxy(simulator: simulator)
        
        if game.player.board.any(isUnknownCard) || game.opponent.board.any(isUnknownCard) {
            errorState = .unknownCards
            logger.error("Board has unknown cards. Exiting")
            return
        }
        
        input.addAvailableRaces(races: game.availableRaces!)
        
        let livingHeroes = game.entities.values.filter({ x in x.isHero && x.health > 0 && !x.isInZone(zone: Zone.removedfromgame) && x.has(tag: .player_tech_level) && (x.isControlled(by: game.player.id) || !x.isInPlay)}).count
        input.setHeroHasDied(value: livingHeroes < game.battlegroundsHeroCount())
        
        guard let oppHero = game.opponent.board.first(where: { $0.isHero }), let playerHero = game.player.board.first(where: { $0.isHero}) else {
            logger.error("Hero(es) could not be found. Exiting.")
            return
        }
        
        var oppHealth = oppHero.health
        if oppHealth <= 0 {
            oppHealth = 1000
        }
        input.setHealths(player: Int32(playerHero.health) + Int32(playerHero[.armor]), opponent: Int32(oppHealth) + Int32(oppHero[.armor]))
        
        let playerTechLevel = playerHero[GameTag.player_tech_level]
        let opponentTechLevel = oppHero[GameTag.player_tech_level]
        input.setTiers(player: Int32(playerTechLevel), opponent: Int32(opponentTechLevel))
        
        let playerHeroPower = game.player.board.first(where: { $0.isHeroPower })
        let opponentHeroPower = game.opponent.board.first(where: { $0.isHeroPower })
        
        input.setPowerID(player: playerHeroPower?.cardId ?? "", opponent: opponentHeroPower?.cardId ?? "")
        
        input.setHeroPower(player: heroPowerUsed(heroPower: playerHeroPower), opponent: heroPowerUsed(heroPower: opponentHeroPower))
        
        let secrets: [Int] = game.player.secrets.map({ $0.card.dbfId })
        
        let playerSecrets = input.getPlayerSecrets()
        
        for i in 0..<secrets.count {
            // secret priority starts at 2
            input.addSecretFromDbfid(id: Int32(secrets[i]), target: playerSecrets)
        }
        
        input.setTurn(value: Int32(turn))
        
        currentOpponentSecrets = game.opponent.secrets
        
        let playerSide = input.getPlayerSide()
        let opponentSide = input.getOpponentSide()
        
        for m in BobsBuddyInvoker.getOrderedMinions(board: game.player.board).filter({e in
            e.isControlled(by: game.player.id)
        }).map({ BobsBuddyInvoker.getMinionFromEntity(ent: $0, attachedEntities: BobsBuddyInvoker.getAttachedEntities(game: game, entityId: $0.id))}) {
            m.addToBackOfList(list: playerSide, sim: simulator)
        }

        for m in BobsBuddyInvoker.getOrderedMinions(board: game.opponent.board).map({ BobsBuddyInvoker.getMinionFromEntity(ent: $0, attachedEntities: BobsBuddyInvoker.getAttachedEntities(game: game, entityId: $0.id))}) {
            m.addToBackOfList(list: opponentSide, sim: simulator)
            
            if m.getReceivesLichKingPower() {
                minionHeroPowerTrigger = MinionHeroPowerTrigger(m: m, heroPower: CardIds.NonCollectible.Neutral.RebornRitesTavernBrawl)
            }
            currentOpponentMinions[Int(m.getGameId())] = m
        }
        
        self.input = input
    }
}
