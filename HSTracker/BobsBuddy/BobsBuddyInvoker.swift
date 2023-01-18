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
import AppCenterCrashes
import SwiftyBeaver

class BobsBuddyDestination: BaseDestination {
    
    override func send(_ level: SwiftyBeaver.Level, msg: String, thread: String, file: String, function: String, line: Int, context: Any? = nil) -> String? {
        let str = super.send(level, msg: msg, thread: thread, file: file, function: function, line: line, context: context)
        
        if let str = str {
            BobsBuddyInvoker.addHDTLogLine(str)
        }
        return str
    }
}

class BobsBuddyInvoker {
    
    let Iterations: Int = 10_000
    let MaxTime: Int = 1_500
    let MaxTimeForComplexBoards = 3_000
    let MinimumSimulationsToReportSentry = 2500
    let StateChangeDelay = 500
    let LichKingDelay = 2000
    
    static let cardIdsWithoutPremiumImplementation: [String] = MinionFactoryProxy.getCardIdsWithoutPremiumImplementations()
    
    static let cardIdsWithCleave: [String] = MinionFactoryProxy.getCardIdsWithCleave()
    
    static let cardIdsWithMegaWindfury: [String] = MinionFactoryProxy.getCardIdsWithMegaWindfury()
    
    var state: BobsBuddyState = .initial
    
    var errorState: BobsBuddyErrorState = .none
    
    var input: InputProxy?
    var output: OutputProxy?
    
    private var opponentMinions = [MinionProxy]()
    private var playerMinions = [MinionProxy]()
    
    private var currentOpponentMinions: [Int: MinionProxy] = [:]
    
    private var currentOpponentSecrets: [Entity] = []
        
    private var _turn: Int = 0
    
    var opponentCardId = ""
    var playerCardId = ""
    
    private final let RebornRite = CardIds.NonCollectible.Neutral.RebornRitesTavernBrawl
    private final let RebornRiteEnchmantment = CardIds.NonCollectible.Neutral.RebornRites_RebornRiteEnchantmentTavernBrawl
    private final let KelThuzadPowerID = "kel'thuzad"
    
    private var _attackingHero: Entity?
    private var _defendingHero: Entity?
    var LastAttackingHero: Entity?
    var LastAttackingHeroAttack: Int = 0
    
    var _instanceKey = ""
    let game: Game
    
    private static var logLinesKept: Int {
        return RemoteConfig.data?.bobs_buddy?.log_lines_kept ?? 100
    }
    
    private static var _recentHDTLog = SynchronizedArray<String>()
    private static let _debugLinesToIgnore = Regex("(Player|Opponent|TagChangeActions)\\.")
    
    fileprivate static func addHDTLogLine(_ string: String) {
        if _debugLinesToIgnore.match(string) {
            return
        }
        if _recentHDTLog.count >= logLinesKept {
            _recentHDTLog.remove(at: 0)
        }
        _recentHDTLog.append(string)
    }
    
    private var runSimulationAfterCombat: Bool {
        return currentOpponentSecrets.count > 0
    }
        
    private static var _instances = SynchronizedDictionary<String, BobsBuddyInvoker>()
    private static var _currentGameId = ""
    
    private static let bobsBuddyDisplay = AppDelegate.instance().coreManager.game.windowManager.bobsBuddyPanel
    
    private init(key: String) {
        _instanceKey = key
        game = AppDelegate.instance().coreManager.game
    }
    
    static func instance(gameId: String, turn: Int, createInstanceIfNoneFound: Bool = true) -> BobsBuddyInvoker? {
        if _currentGameId != gameId {
            logger.debug("New GameId. Clearing instances...")
            _instances.removeAll()
        }
        _currentGameId = gameId
        
        let key = "\(gameId)_\(turn)"
        
        if let inst = _instances[key] {
            return inst
        } else if createInstanceIfNoneFound {
            let inst = BobsBuddyInvoker(key: key)
            _instances[key] = inst
            return inst
        }
        return nil
    }
    
    func shouldRun() -> Bool {
        if !Settings.showBobsBuddy || !game.isBattlegroundsMatch() {
            return false
        }
        return true
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
        
        snapshotBoardState(turn: game.turnNumber())
        
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
                
        if let input = input, (input.playerHeroPower.cardId == RebornRite && input.playerHeroPower.isActivated) || (input.opponentHeroPower.cardId == RebornRite && input.opponentHeroPower.isActivated) {
            Thread.sleep(forTimeInterval: Double(LichKingDelay) / 1000.0)
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
                if top.simulationCount <= 500 && top.getMyExitCondition() ==  .time {
                    logger.debug("Could not perform enough simulations. Displaying error state and exiting.")
                    self.errorState = .notEnoughData
                    BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .notEnoughData)
                } else {
                    logger.debug("Displaying simulation results")
                    let winRate = top.winRate
                    let tieRate = top.tieRate
                    let lossRate = top.lossRate
                    let myDeathRate = top.myDeathRate
                    let theirDeathRate = top.theirDeathRate
                    let possibleResults = top.getResultDamage()
                    
                    BobsBuddyInvoker.bobsBuddyDisplay.showCompletedSimulation(winRate: winRate, tieRate: tieRate, lossRate: lossRate, playerLethal: theirDeathRate, opponentLethal: myDeathRate, possibleResults: possibleResults)
                }
                self.output = top
                seal.fulfill(true)
            }.catch({ error in
                logger.error("Error running simulation: \(error.localizedDescription)")
                BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .failedToLoad)
                Analytics.trackEvent("runSimulation failed", withProperties: [ "error": error.localizedDescription])
                seal.fulfill(false)
            })
        }
    }
    
    func runSimulation() -> Promise<OutputProxy?> {
        logger.info("Starting simulation")
        return Promise<OutputProxy?> { seal in
            DispatchQueue.global().async {
                let opaque = mono_thread_attach(MonoHelper._monoInstance)
                
                var result: OutputProxy?
                
                if let inp = self.input {
                    if self.runSimulationAfterCombat {
                        let secrets: [Int] = self.currentOpponentSecrets.map({ $0.card.dbfId })
                        let opponentSecrets = inp.opponentSecrets
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
                    
                    let ps = inp.playerSide
                    let os = inp.opponentSide
                    let at = (MonoHelper.listCount(obj: ps) > 6 || MonoHelper.listCount(obj: os) > 6) ? self.MaxTimeForComplexBoards : self.MaxTime
                    
                    logger.debug("Running simulations with MaxIterations=\(self.Iterations) and ThreadCount=\(tc)...")

                    let start = DispatchTime.now()
                    
                    let task = simulator.simulateMultiThreaded(input: inp, maxIterations: self.Iterations, threadCount: tc, maxDuration: at)
                    
                    let tinst = task.get()
                    let c = mono_object_get_class(tinst)

                    let mw = MonoHelper.getMethod(c, "Wait", 0)
                    
                    _ = mono_runtime_invoke(mw, tinst, nil, nil)
                    
                    let mr = MonoHelper.getMethod(c, "get_Result", 0)
                    let output = mono_runtime_invoke(mr, tinst, nil, nil)
                    
                    let top = OutputProxy(obj: output)
                    
                    let ellapsed = (DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                    
                    logger.debug("----- Simulation Output -----")
                    logger.debug("Duration=\(ellapsed)ms, ExitCondition=\(top.getMyExitCondition()), Iterations = \(top.simulationCount)")
                    logger.debug("WinRate=\(top.winRate * 100)% (Lethal=\(top.theirDeathRate * 100)%), TieRate=\(top.tieRate * 100)%, LossRate=\(top.lossRate * 100)% (Lethal=\(top.myDeathRate * 100)%)")
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
    
    func startShopping(validate: Bool = true) {
        if state == .shopping {
            logger.debug("Already in shopping state. Exiting")
            return
        }
        state = .shopping
        BobsBuddyInvoker.bobsBuddyDisplay.setState(st: .shopping)
        if !runSimulationAfterCombat {
            logger.debug("Setting UI state to shopping")
            if validate {
                validateSimulationResult()
            }
        } else {
             _ = runAndDisplaySimulationAsync().done { _ in
                 if validate {
                     self.validateSimulationResult()
                 }
            }.catch { error in
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
    
    func updateAttackingEntities(attacker: Entity, defender: Entity) {
        guard attacker.isHero && defender.isHero else {
            return
        }
        logger.debug("Updating entities with attacker=\(attacker.card.name), defender=\(defender.card.name)")
        _defendingHero = defender
        _attackingHero = attacker
    }
    
    func handleNewAttackingEntity(newAttacker: Entity) {
        if newAttacker.isHero {
            LastAttackingHero = newAttacker
            LastAttackingHeroAttack = newAttacker.attack
        }
    }
    
    private func getLastCombatDamageDealt() -> Int {
        if LastAttackingHero != nil {
            return LastAttackingHeroAttack
        }
        return 0
    }
    
    private func getLastCombatResult() -> CombatResult {
        guard let LastAttackingHero = LastAttackingHero else {
            return .tie
        }
        let playerHero = game.entities.values.first { x in x.cardId == playerCardId }
        let opponentHero = game.entities.values.first { x in x.cardId == opponentCardId }
        
        if let playerHero = playerHero, let opponentHero = opponentHero {
            if LastAttackingHero.cardId == playerHero.cardId {
                return .win
            }
            if LastAttackingHero.cardId == opponentHero.cardId {
                return .loss
            }
        }
        return .invalid
    }
    
    private func getLastLethalResult() -> LethalResult {
        guard let defendingHero = _defendingHero, let attackingHero = _attackingHero else {
            return .noOneDied
        }

        let totalDefenderHealth = defendingHero.health + defendingHero[.armor]
        if attackingHero.attack >= totalDefenderHealth {
            if attackingHero.isControlled(by: game.player.id) {
                return .opponentDied
            } else {
                return .friendlyDied
            }
        }
        return .noOneDied
    }
    
    private func validateSimulationResult() {
        DispatchQueue.global().async {
            self.validateSimulationResultInternal()
        }
    }
    
    private func validateSimulationResultInternal() {
        let opaque = mono_thread_attach(MonoHelper._monoInstance)
        
        defer {
            mono_thread_detach(opaque)
        }
        logger.debug("Validating results...")
        guard let output = output else {
            logger.debug("_lastSimulationResult is null. Exiting")
            return
        }
        if output.simulationCount < MinimumSimulationsToReportSentry {
            logger.debug("Did not complete enough simulations to report terminal cases. Exiting.")
            return
        }
        
        let metricSampling = RemoteConfig.data?.bobs_buddy?.metric_sampling ?? 0
        let reportErrors = RemoteConfig.data?.bobs_buddy?.sentry_reporting ?? false
        
        logger.debug("metricSampling=\(metricSampling), reportErrors=\(reportErrors)")
        
        if !reportErrors && metricSampling == 0 {
            logger.debug("Nothing to report. Exiting.")
            return
        }
        
        //We delay checking the combat results because the tag changes can sometimes be read by the parser with a bit of delay after they're printed in the log.
        //Without this delay they can occasionally be missed.
        
        Thread.sleep(forTimeInterval: 0.100)
        let result = getLastCombatResult()
        let lethalResult = getLastLethalResult()
        
        logger.debug("result=\(result), lethalResult=\(lethalResult)")
        
        if lethalResult == .friendlyDied && game.wasConceded {
            logger.debug("Game was conceded. Not reporting.")
            return
        }
        
//        var terminalCase = false
        
        if isIncorrectCombatResult(result: result) {
//            terminalCase = true
            if reportErrors {
                alertWithLastInputOutput(result: "\(result)")
            }
        }
        
        if isIncorrectLethalResult(result: lethalResult) && !opposingKelThuzadDied(result: lethalResult) {
            // Akazamzarak hero power - secrets are supported but not for lethal.
            if input?.opponentHeroPower.cardId == CardIds.NonCollectible.Neutral.PrestidigitationTavernBrawl {
                logger.debug("Opponent was Akazamarak. Currently not reporting lethal results. Exiting.")
                return
            }
            
            // There should never be relevant lethals this early in the game.
            // These missed lethals are likely caused by some bug.
            if _turn <= 5 {
                logger.debug("There should not be missed lethals on turn ${_turn}, this is probably a bug. This won't be reported.")
                return
            }
//            terminalCase = true
            if reportErrors {
                alertWithLastInputOutput(result: "\(lethalResult)")
            }
        }   
//        Analytics.trackEvent("BobsBuddy_SimulationComplete", withProperties: [
//            "result": "\(result)",
//            "terminal_case": "\(terminalCase)",
//            "turn": "\(_turn)",
//            "exit_condition": "\(output.getMyExitCondition())",
//            "thread_count": "\(ProcessInfo.processInfo.activeProcessorCount / 2)",
//            "removed_lich_king": "\(_removedLichKingHeroPowerFromMinion)",
//            "can_remove_lich_king": "\(canRemoveLichKing)",
//            "iterations": "\(output.getSimulationCount())",
//            "result_win": "\(result == .win ? 1 : 0)",
//            "result_tie": "\(result == .tie ? 1 : 0)",
//            "result_loss": "\(result == .loss ? 1 : 0)",
//            "win_rate": "\(output.getWinRate() * 100.0)",
//            "tie_rate": "\(output.getTieRate() * 100.0)",
//            "loss_rate": "\(output.getLossRate() * 100.0)"
//        ])
    }
    
    private func alertWithLastInputOutput(result: String) {
        logger.debug("Queing alert... (valind input: \(input != nil)")
        if let input = input, let output = output {
            Sentry.queueBobsBuddyTerminalCase(type: "BobsBuddy_TerminalCase", message: "BobsBuddy Terminal Case", properties: [
                "turn": "\(_turn)",
                "result": "\(result)",
                "threadCount": "\(ProcessInfo.processInfo.activeProcessorCount / 2)",
                "iterations": "\(output.simulationCount)",
                "exitCondition": "\(output.getMyExitCondition())",
                "output": MonoHelper.toString(obj: output)], input: input.unitestCopyableVersion(), log: BobsBuddyInvoker._recentHDTLog.array().joined(separator: "\n"))
        }
    }
    
    private func isIncorrectCombatResult(result: CombatResult) -> Bool {
        return result == .tie && output?.tieRate == 0 ||
        result == .win && output?.winRate == 0 ||
        result == .loss && output?.lossRate == 0
    }
    
    private func isIncorrectLethalResult(result: LethalResult) -> Bool {
        return result == .friendlyDied && output?.myDeathRate == 0 ||
        result == .opponentDied && output?.theirDeathRate == 0
    }
    
    private func opposingKelThuzadDied(result: LethalResult) -> Bool {
        guard let input = input else {
            return false
        }

        return result == .opponentDied && input.opponentHeroPower.cardId == KelThuzadPowerID
    }
    
    func isUnknownCard(e: Entity?) -> Bool {
        return e?.card.id == "unknown"
    }
    
    func wasHeroPowerUsed(heroPower: Entity?) -> Bool {
        return (heroPower?.has(tag: GameTag.exhausted) ?? false || heroPower?.has(tag: GameTag.bacon_hero_power_activated) ?? false)
    }
    
    static func getOrderedMinions(board: [Entity]) -> [Entity] {
        // swiftlint:disable force_cast
        return board.filter({ $0.isMinion }).map({ $0.copy() as! Entity }).sorted(by: { $0[GameTag.zone_position] < $1[GameTag.zone_position]})
        // swiftlint:enable force_cast
    }
    
    static func getMinionFromEntity(minionFactory: MinionFactoryProxy, player: Bool, ent: Entity, attachedEntities: [Entity]) -> MinionProxy {
        let cardId = ent.info.latestCardId
        let minion = minionFactory.createFromCardid(id: cardId, player: player)
        
        minion.baseAttack = Int32(ent[GameTag.atk])
        minion.baseHealth = Int32(ent[GameTag.health])
        minion.taunt = ent.has(tag: GameTag.taunt)
        minion.div = ent.has(tag: GameTag.divine_shield)
        if cardIdsWithCleave.contains(cardId) {
            minion.cleave = true
        }
        minion.poisonous = ent.has(tag: GameTag.poisonous)
        minion.windfury = ent.has(tag: GameTag.windfury)
        minion.megaWindfury = ent.has(tag: GameTag.mega_windfury) || cardIdsWithMegaWindfury.contains(cardId)
        minion.stealth = ent.has(tag: .stealth)
        
        let golden = ent.has(tag: GameTag.premium)
        minion.golden = golden
        minion.tier = Int32(ent[GameTag.tech_level])
        minion.reborn = ent.has(tag: GameTag.reborn)
        
        if golden && (BobsBuddyInvoker.cardIdsWithoutPremiumImplementation.firstIndex(of: cardId) != nil) {
            minion.vanillaAttack *= 2
            minion.vanillaHealth *= 2
        }
        
        for ent in attachedEntities {
            switch ent.cardId {
            case CardIds.NonCollectible.Neutral.RebornRitesTavernBrawl:
                minion.reborn = true
            case CardIds.NonCollectible.Neutral.ReplicatingMenace_ReplicatingMenaceEnchantment:
                minion.addDeathrattle(deathrattle: ReplicatingMenace.deathrattle(golden: false))
            case CardIds.NonCollectible.Neutral.ReplicatingMenace_ReplicatingMenaceEnchantmentTavernBrawl:
                minion.addDeathrattle(deathrattle: ReplicatingMenace.deathrattle(golden: true))
            case CardIds.NonCollectible.Neutral.LivingSporesToken2:
                minion.addDeathrattle(deathrattle: GenericDeathrattles.plants())
            case CardIds.NonCollectible.Neutral.Sneed_Replicate:
                minion.addDeathrattle(deathrattle: GenericDeathrattles.sneedHeroPower())
            case CardIds.NonCollectible.Neutral.Brukan_ElementEarth:
                minion.addDeathrattle(deathrattle: GenericDeathrattles.earthInvocation())
            case CardIds.NonCollectible.Neutral.Brukan_EarthRecollection:
                minion.addDeathrattle(deathrattle: BrukanInvocationDeathrattles.earth())
            case CardIds.NonCollectible.Neutral.Brukan_FireRecollection:
                minion.addDeathrattle(deathrattle: BrukanInvocationDeathrattles.fire())
            case CardIds.NonCollectible.Neutral.Brukan_WaterRecollection:
                minion.addDeathrattle(deathrattle: BrukanInvocationDeathrattles.water())
            case CardIds.NonCollectible.Neutral.Brukan_LightningRecollection:
                minion.addDeathrattle(deathrattle: BrukanInvocationDeathrattles.lightning())
            case CardIds.NonCollectible.Neutral.Wingmen_WingmenEnchantmentTavernBrawl:
                minion.hasWingmen = true
            default:
                break
            }
        }
        
        minion.gameId = Int32(ent.id)
        return minion
    }
    
    static func getAttachedEntities(game: Game, entityId: Int) -> [Entity] {
        // swiftlint:disable force_cast
        return game.entities.values.filter({ $0.isAttachedTo(entityId: entityId) && ($0.isInPlay || $0.isInSetAside || $0.isInGraveyard) }).map({ $0.copy() as! Entity })
        // swiftlint:enable force_cast
    }

    func snapshotBoardState(turn: Int) {
        logger.debug("Snapshotting board state...")
        LastAttackingHero = nil
        
        let simulator = SimulatorProxy()
        let input = InputProxy(simulator: simulator)
        
        if game.player.board.any(isUnknownCard) || game.opponent.board.any(isUnknownCard) {
            errorState = .unknownCards
            logger.error("Board has unknown cards. Exiting")
            return
        }
        
        guard let races = game.availableRaces else {
            errorState = .unknownCards
            logger.error("Game has no available races. Exiting")
            return
        }
        input.addAvailableRaces(races: races)

        input.damageCap = Int32(game.gameEntity?[.bacon_combat_damage_cap] ?? 0)
        
        guard let oppHero = game.opponent.board.first(where: { $0.isHero }), let playerHero = game.player.board.first(where: { $0.isHero}) else {
            logger.error("Hero(es) could not be found. Exiting.")
            return
        }
        
        var oppHealth = oppHero.health
        if oppHealth <= 0 {
            oppHealth = 1000
        }
        input.setHealths(player: Int32(playerHero.health) + Int32(playerHero[.armor]), opponent: Int32(oppHealth) + Int32(oppHero[.armor]))
        
        //We set OpponentCardId and PlayerCardId here so that later we can do lookups for these entites without using _game.Opponent/Player, which might be innacurate or null depending on when they're accessed.
        opponentCardId = oppHero.cardId
        playerCardId = playerHero.cardId
        
        let playerTechLevel = playerHero[GameTag.player_tech_level]
        let opponentTechLevel = oppHero[GameTag.player_tech_level]
        input.setTiers(player: Int32(playerTechLevel), opponent: Int32(opponentTechLevel))
        
        let playerHeroPower = game.player.board.first(where: { $0.isHeroPower })
        
        input.setPlayerHeroPower(heroPowerCardId: playerHeroPower?.cardId ?? "", isActivated: wasHeroPowerUsed(heroPower: playerHeroPower), data: Int32(playerHeroPower?[.tag_script_data_num_1] ?? 0))
        
        let opponentHeroPower = game.opponent.board.first(where: { $0.isHeroPower })
        
        input.setOpponentHeroPower(heroPowerCardId: opponentHeroPower?.cardId ?? "", isActivated: wasHeroPowerUsed(heroPower: opponentHeroPower), data: Int32(opponentHeroPower?[.tag_script_data_num_1] ?? 0))
        
        let playerQuests = input.playerQuests
        for quest in game.player.quests {
            let rewardDbfId = quest[.quest_reward_database_id]
            let reward = Cards.by(dbfId: rewardDbfId, collectible: false)
            let questData = QuestDataProxy()
            questData.questProgress = Int32(quest[.quest_progress])
            questData.questProgressTotal = Int32(quest[.quest_progress_total])
            questData.questCardId = quest.cardId
            questData.rewardCardId = reward?.id ?? ""
            MonoHelper.addToList(list: playerQuests, element: questData)
        }

        for reward in game.player.questRewards {
            let questData = QuestDataProxy()
            questData.questProgress = Int32(0)
            questData.questProgressTotal = Int32(0)
            questData.questCardId = ""
            questData.rewardCardId = reward.info.latestCardId
            MonoHelper.addToList(list: playerQuests, element: questData)
        }

        let opponentQuests = input.opponentQuests
        for quest in game.opponent.quests {
            let rewardDbfId = quest[.quest_reward_database_id]
            let reward = Cards.by(dbfId: rewardDbfId, collectible: false)
            let questData = QuestDataProxy()
            questData.questProgress = Int32(quest[.quest_progress])
            questData.questProgressTotal = Int32(quest[.quest_progress_total])
            questData.questCardId = quest.cardId
            questData.rewardCardId = reward?.id ?? ""
            MonoHelper.addToList(list: opponentQuests, element: questData)
        }

        for reward in game.opponent.questRewards {
            let questData = QuestDataProxy()
            questData.questProgress = Int32(0)
            questData.questProgressTotal = Int32(0)
            questData.questCardId = ""
            questData.rewardCardId = reward.info.latestCardId
            MonoHelper.addToList(list: opponentQuests, element: questData)
        }

        input.setPlayerHandSize(value: Int32(game.player.handCount))
        
        let secrets: [Int] = game.player.secrets.map({ $0.card.dbfId })
        
        let playerSecrets = input.playerSecrets
        
        for i in 0..<secrets.count {
            // secret priority starts at 2
            input.addSecretFromDbfid(id: Int32(secrets[i]), target: playerSecrets)
        }
        
        input.setTurn(value: Int32(turn))
        
        currentOpponentSecrets = game.opponent.secrets
        
        let inputPlayerSide = input.playerSide
        let inputOpponentSide = input.opponentSide
        let factory = simulator.minionFactory
        
        let playerSide = BobsBuddyInvoker.getOrderedMinions(board: game.player.board).filter { e in e.isControlled(by: game.player.id) }.map { BobsBuddyInvoker.getMinionFromEntity(minionFactory: factory, player: true, ent: $0, attachedEntities: BobsBuddyInvoker.getAttachedEntities(game: game, entityId: $0.id))}
        playerMinions = playerSide
        for m in playerSide {
            MonoHelper.addToList(list: inputPlayerSide, element: m)
        }

        let opponentSide = BobsBuddyInvoker.getOrderedMinions(board: game.opponent.board).filter { e in e.isControlled(by: game.opponent.id) }.map { BobsBuddyInvoker.getMinionFromEntity(minionFactory: factory, player: false, ent: $0, attachedEntities: BobsBuddyInvoker.getAttachedEntities(game: game, entityId: $0.id))}
        opponentMinions = opponentSide
        for m in opponentSide {
            MonoHelper.addToList(list: inputOpponentSide, element: m)
        }
        
        let playerAttached = BobsBuddyInvoker.getAttachedEntities(game: game, entityId: game.player.id)
        let pEternalLegion = playerAttached.first { x in x.cardId == CardIds.NonCollectible.Neutral.EternalKnight_EternalKnightPlayerEnchant }
        if let pEternalLegion {
            input.playerEternalKnightCounter = Int32(pEternalLegion[.tag_script_data_num_1])
        }
        let pUndeadBonus = playerAttached.first { x in x.cardId == CardIds.NonCollectible.Neutral.NerubianDeathswarmer_UndeadBonusAttackPlayerEnchantDnt }
        if let pUndeadBonus {
            input.playerUndeadAttackBonus = Int32(pUndeadBonus[.tag_script_data_num_1])
        }

        let opponentAttached = BobsBuddyInvoker.getAttachedEntities(game: game, entityId: game.opponent.id)
        let oEternalLegion = opponentAttached.first { x in x.cardId == CardIds.NonCollectible.Neutral.EternalKnight_EternalKnightPlayerEnchant }
        if let oEternalLegion {
            input.opponentEternalKnightCounter = Int32(oEternalLegion[.tag_script_data_num_1])
        }
        let oUndeadBonus = opponentAttached.first { x in x.cardId == CardIds.NonCollectible.Neutral.NerubianDeathswarmer_UndeadBonusAttackPlayerEnchantDnt }
        if let oUndeadBonus {
            input.opponentUndeadAttackBonus = Int32(oUndeadBonus[.tag_script_data_num_1])
        }

        logger.info("pEternal=\(input.playerEternalKnightCounter), pUndead=\(input.playerUndeadAttackBonus) | oEternal={\(input.opponentEternalKnightCounter), oUndead=\(input.opponentUndeadAttackBonus)");

        self.input = input
        self._turn = turn
    }
}
