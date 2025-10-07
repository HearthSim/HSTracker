//
//  BobsBuddyInvoker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/14/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftyBeaver
import Sentry

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
    let MaxTimeForLeapfrogger = 5_000
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
    
    var doNotReport = true
    
    private var currentOpponentMinions: [Int: MinionProxy] = [:]
    
    private var opponentHand: [Entity] = []
    private var opponentHandMap: [Entity: Entity] = [:]
    private var opponentSecrets: [Entity] = []
        
    private var _turn: Int = 0
    
    private final let RebornRite = CardIds.NonCollectible.Neutral.RebornRitesTavernBrawl
    private final let RebornRiteEnchmantment = CardIds.NonCollectible.Neutral.RebornRites_RebornRiteEnchantmentTavernBrawl
    private final let KelThuzadPowerID = "kel'thuzad"
    
    private var _attackingHero: Entity?
    private var _defendingHero: Entity?
    var LastAttackingHero: Entity?
    var LastAttackingHeroAttack: Int = 0
    
    static private let WhirringProtector_Normal = CardIds.NonCollectible.Neutral.WhirringProtector_WhirringProtectorEnchantment
    static private let WhirringProtector_Golden = CardIds.NonCollectible.Neutral.WhirringProtector_WhirringProtector2
    
    var _instanceKey = ""
    let game: Game
    
    private static var logLinesKept: Int {
        return RemoteConfig.data?.bobs_buddy?.log_lines_kept ?? 100
    }
    
    private static var _recentHDTLog = SynchronizedArray<String>()
    private static let _debugLinesToIgnore = Regex("(Player|Opponent|TagChangeActions)\\.")
    
    private var duosInputPlayer: PlayerProxy
    private var duosInputOpponent: PlayerProxy
    private var duosInputPlayerTeammate: PlayerProxy?
    private var duosInputOpponentTeammate: PlayerProxy?
    
    fileprivate static func addHDTLogLine(_ string: String) {
        if _debugLinesToIgnore.match(string) {
            return
        }
        if _recentHDTLog.count >= logLinesKept {
            _recentHDTLog.remove(at: 0)
        }
        _recentHDTLog.append(string)
    }
    
    private static var _instances = SynchronizedDictionary<String, BobsBuddyInvoker>()
    private static var _currentGameId = ""
    
    private static let bobsBuddyDisplay = AppDelegate.instance().coreManager.game.windowManager.bobsBuddyPanel
    
    private init(key: String) {
        _instanceKey = key
        game = AppDelegate.instance().coreManager.game
        
        let opaque = mono_thread_attach(MonoHelper._monoInstance)
        
        defer {
            mono_thread_detach(opaque)
        }
        duosInputPlayer = PlayerProxy(input: nil)
        duosInputOpponent = PlayerProxy(input: nil)
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
        if !Settings.showBobsBuddy {
            return false
        }
        return true
    }
    
    func startCombat() {
        opponentHand = [Entity]()
        opponentSecrets = [Entity]()
        
        if !shouldRun() {
            return
        }
        DispatchQueue.global().async { [self] in
            let opaque = mono_thread_attach(MonoHelper._monoInstance)
            
            defer {
                mono_thread_detach(opaque)
            }
            
            if game.isBattlegroundsDuosMatch() {
                snapshotBoardState(turn: game.turnNumber())
                BobsBuddyInvoker.bobsBuddyDisplay.setState(st: .waitingForTeammates)
                DispatchQueue.main.async {
                    BobsBuddyInvoker.bobsBuddyDisplay.resetText()
                }
                if input != nil && (duosInputPlayerTeammate == nil || duosInputOpponentTeammate == nil) {
                    logger.debug("Waiting Teammates. Exiting.")
                    return
                }
            }
            
            if state.rawValue >= BobsBuddyState.combat.rawValue {
                logger.debug("Already in \(state) state. Exiting")
                return
            } else {
                snapshotBoardState(turn: game.turnNumber())
            }
            logger.info("State is now combat")
            state = .combat
            
            Thread.sleep(forTimeInterval: Double(StateChangeDelay) / 1_000.0)
            
            if state != .combat {
                logger.debug("No longer in combat: State=\(state). Exiting")
                return
            }
            if hasErrorState() {
                return
            }
            
            logger.debug("Setting UI state to combat...")
            BobsBuddyInvoker.bobsBuddyDisplay.setState(st: .combat)
            
            func hpAny(_ list: MonoHandle) -> Bool {
                let heroPowers = MonoHelper.listItems(obj: list)
                
                return heroPowers.any { obj in
                    let hp = HeroPowerDataProxy(obj: obj.get())
                    
                    return hp.cardId == RebornRite && hp.isActivated
                }
            }
            
            if let input = input, hpAny(input.player.heroPowers) || hpAny(input.opponent.heroPowers) {
                Thread.sleep(forTimeInterval: Double(LichKingDelay) / 1000.0)
            }
            
            _ = runAndDisplaySimulationAsync().catch({ error in
                logger.error("Error running simulation: \(error.localizedDescription)")
                BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .failedToLoad)
                var inputString = ""
                if let input = self.input {
                    inputString = input.unitestCopyableVersion()
                }
                Influx.sendEvent(eventName: "runSimulation failed", withProperties: [ "error": error.localizedDescription, "input": inputString ])
            })
        }
    }
    
    func maybeRunDuosPartialCombat() -> Promise<Bool> {
        return Promise<Bool> { seal in
            if input != nil && !(duosInputPlayerTeammate == nil || duosInputOpponentTeammate == nil) {
                logger.debug("No need to run partial combat, all teammates found. Exiting.")
                seal.fulfill(false)
                return
            }
            if !shouldRun() {
                seal.fulfill(false)
                return
            }
            
            if hasErrorState() {
                seal.fulfill(false)
                return
            }
            
            state = .combatPartial
            logger.debug("Setting UI state to combat...")
            
            BobsBuddyInvoker.bobsBuddyDisplay.setState(st: .combatPartial)
            DispatchQueue.main.async {
                BobsBuddyInvoker.bobsBuddyDisplay.resetText()
            }
            
            // Enforce input teammate to be null if teammate was not snapshot
            if input != nil && duosInputPlayerTeammate == nil {
                input?.playerTeammate = PlayerProxy(obj: nil)
            }
            if input != nil && duosInputOpponentTeammate == nil {
                input?.opponentTeammate = PlayerProxy(obj: nil)
            }
            
            _ = runAndDisplaySimulationAsync().done { _ in
                seal.fulfill(true)
            }.catch { error in
                logger.debug(error)
                seal.fulfill(false)
            }
        }
    }
    
    func runAndDisplaySimulationAsync() -> Promise<Bool> {
        return Promise<Bool> { seal in
            currentOpponentMinions.removeAll()
            logger.debug("Running simulation...")
            DispatchQueue.main.async {
                BobsBuddyInvoker.bobsBuddyDisplay.hidePercentagesShowSpinners()
            }
            _ = runSimulation().done { (result) in
                guard let top = result, let input = self.input else {
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
                } else if self.state == .combatPartial {
                    logger.debug("Displaying partial simulation results")
                    let winRate = top.winRate
                    let tieRate = top.tieRate
                    let lossRate = top.lossRate
                    let myDeathRate = top.myDeathRate
                    let theirDeathRate = top.theirDeathRate
                    let possibleResults = top.getResultDamage()
                    let friendlyWon = self.duosInputPlayerTeammate == nil
                    let playerCanDie = input.player.health <= input.damageCap
                    let opponentCanDie = input.opponent.health <= input.damageCap
                    
                    DispatchQueue.main.async {
                        BobsBuddyInvoker.bobsBuddyDisplay.showPartialDuosSimulation(winRate: winRate, tieRate: tieRate, lossRate: lossRate, playerLethal: theirDeathRate, opponentLethal: myDeathRate, possibleResults: possibleResults, friendlyWon: friendlyWon, playerCanDie: playerCanDie, opponentCanDie: opponentCanDie)
                    }
                } else {
                    logger.debug("Displaying simulation results")
                    let winRate = top.winRate
                    let tieRate = top.tieRate
                    let lossRate = top.lossRate
                    let myDeathRate = top.myDeathRate
                    let theirDeathRate = top.theirDeathRate
                    let possibleResults = top.getResultDamage()
                    
                    DispatchQueue.main.async {
                        BobsBuddyInvoker.bobsBuddyDisplay.showCompletedSimulation(winRate: winRate, tieRate: tieRate, lossRate: lossRate, playerLethal: theirDeathRate, opponentLethal: myDeathRate, possibleResults: possibleResults)
                    }
                }
                self.output = top
                seal.fulfill(true)
            }.catch({ error in
                logger.error("Error running simulation: \(error.localizedDescription)")
                BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .failedToLoad)
                Influx.sendEvent(eventName: "runSimulation failed", withProperties: [ "error": error.localizedDescription])
                seal.fulfill(false)
            })
        }
    }
    
    func runSimulation() -> Promise<OutputProxy?> {
        logger.info("Starting simulation")
        return Promise<OutputProxy?> { seal in
            DispatchQueue.global().async {
                Influx.breadcrumb(eventName: "running_simulation", withProperties: ["turn": "\(self.game.turnNumber())"])

                let opaque = mono_thread_attach(MonoHelper._monoInstance)
                
                var result: OutputProxy?
                
                if let inp = self.input {
                    let target = inp.opponent.secrets
                    var secrets = [Int?]()
                    var seen = Set<Int>()
                    for dbfid in self.game.opponent.secrets.compactMap({ x in
                        !x.cardId.isEmpty ? x.card.dbfId : nil }) {
                        if dbfid == 0 {
                            secrets.append(nil)
                        } else if !seen.contains(dbfid) {
                            secrets.append(dbfid)
                            seen.insert(dbfid)
                        }
                    }
                    for secret in secrets {
                        inp.addSecretFromDbfid(id: secret, target: target)
                    }
                    logger.debug("Set opponent S. with \(secrets.count) S.")
                    logger.debug("----- Simulation Input -----")
                    let str = inp.unitestCopyableVersion()
                    
                    logger.debug(str)
                    logger.debug("----- End of Input -----")
                    
                    let tc = ProcessInfo.processInfo.activeProcessorCount / 2
                    let simulator = SimulationRunnerProxy()
                    
                    var at = self.MaxTime
                    
                    logger.debug("Running simulations with MaxIterations=\(self.Iterations) and ThreadCount=\(tc)...")

                    do {
                        func isLeapFroggerCombo(_ side: MonoHandle) -> Bool {
                            guard side.get() != nil else {
                                return false
                            }
                            let cnt = MonoHelper.listCount(obj: side)
                            if cnt < 3 {
                                return false
                            }
                            for i in 0 ..< cnt {
                                let item = MonoHelper.listItem(obj: side, index: Int32(i))
                                if item.get() != nil {
                                    let minion = MinionProxy(obj: item.get())
                                    if minion.cardID == CardIds.NonCollectible.Neutral.Leapfrogger {
                                        return true
                                    }
                                }
                            }
                            return false
                        }
                        if isLeapFroggerCombo(inp.player.side) || isLeapFroggerCombo(inp.playerTeammate.side) || isLeapFroggerCombo(inp.opponent.side) || isLeapFroggerCombo(inp.opponentTeammate.side) {
                            at = self.MaxTimeForLeapfrogger
                        } else if MonoHelper.listCount(obj: inp.player.side) >= 6 || MonoHelper.listCount(obj: inp.opponent.side) >= 6 {
                            at = self.MaxTimeForComplexBoards
                        }
                        let start = DispatchTime.now()
                        
                        let task = simulator.simulateMultiThreaded(input: inp, maxIterations: self.Iterations, threadCount: tc, maxDuration: at)
                        
                        let tinst = task.get()
                        let c = mono_object_get_class(tinst)
                        
                        let mw = MonoHelper.getMethod(c, "Wait", 0)
                        
                        let exc = UnsafeMutablePointer<UnsafeMutablePointer<MonoObject>?>.allocate(capacity: 1)
                        exc[0] = nil
                        
                        defer {
                            exc.deallocate()
                        }
                        
                        _ = mono_runtime_invoke(mw, tinst, nil, exc)

                        if let exc = exc[0] {
                            var ae: AggregateExceptionProxy! = AggregateExceptionProxy(obj: exc)
                            var ex: UnsupportedInteractionExceptionProxy?
                            while let aggregate = ae, MonoHelper.isInstance(obj: aggregate, klass: AggregateExceptionProxy._class!) {
                                let inner = aggregate.innerException
                                if let class_ = UnsupportedInteractionExceptionProxy._class, MonoHelper.isInstance(obj: inner, klass: class_) {
                                    ex = UnsupportedInteractionExceptionProxy(obj: inner.get())
                                    break
                                } else if let class_ = AggregateExceptionProxy._class, MonoHelper.isInstance(obj: aggregate, klass: class_) {
                                    ae = AggregateExceptionProxy(obj: inner.get())
                                } else {
                                    break
                                }
                            }
                            if let ex {
                                let entity = ex.entity
                                var str = ""
                                var cardName: String?
                                if entity.get() != nil {
                                    str = MonoHelper.toString(obj: entity)
                                    cardName = Cards.by(cardId: entity.cardID)?.name
                                }
                                logger.debug("Unsupported interaction: \(str): \(ex.message)")
                                logger.error(MonoHelper.toString(obj: ex))
                                let message = "\(cardName ?? ""): \(ex.message)"
                                throw UnsupportedInteraction(message: message)
                            }
                            let exception = MonoHandle(obj: exc)
                            let str = MonoHelper.toString(obj: exception)
                            logger.debug(str)
                            throw RuntimeError(str)
                        }
                        
                        let mr = MonoHelper.getMethod(c, "get_Result", 0)
                        let output = mono_runtime_invoke(mr, tinst, nil, nil)
                        
                        let top = OutputProxy(obj: output)
                        
                        let ellapsed = (DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                        
                        self.doNotReport = false
                        logger.debug("----- Simulation Output -----")
                        logger.debug("Duration=\(ellapsed)ms, ExitCondition=\(top.getMyExitCondition()), Iterations = \(top.simulationCount)")
                        logger.debug("WinRate=\(top.winRate * 100)% (Lethal=\(top.theirDeathRate * 100)%), TieRate=\(top.tieRate * 100)%, LossRate=\(top.lossRate * 100)% (Lethal=\(top.myDeathRate * 100)%)")
                        logger.debug("----- End of Output -----")
                        
                        result = top
                        
                        Influx.breadcrumb(eventName: "simulation_complete", withProperties: ["turn": "\(self.game.turnNumber())"])
                    } catch let error as UnsupportedInteraction {
                        BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .unsupportedInteraction, message: error.message)
                        result = nil
                    } catch {
                        var inputString = ""
                        if let input = self.input {
                            inputString = input.unitestCopyableVersion()
                        }
                        SentrySDK.capture(error: error, block: { scope in
                            if inputString.count != 0 {
                                scope.addAttachment(Attachment(data: inputString.data(using: .utf8) ?? Data(), filename: "input.cs", contentType: "application/text"))
                            }
                        })
                        logger.error("Unknown error")
                        BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .none)
                        result = nil
                    }
                } else {
                    logger.error("No input")
                }
                
                mono_thread_detach(opaque)
                seal.fulfill(result)
            }
        }
    }
    
    func startShopping(isGameOver: Bool = true) {
        if !shouldRun() {
            return
        }
        logger.debug("\(_instanceKey)")
        if state == .shopping || state == .shoppingAfterPartial {
            logger.debug("\(_instanceKey) already in shopping state. Exiting")
            return
        }
        let wasPreviousStatePartial = state == .combatPartial
        if isGameOver {
            if state != .initial {
                logger.debug("Setting UI state to GameOver")
                state = wasPreviousStatePartial ? .gameOverAfterPartial : .gameOver
            }
        } else {
            logger.debug("Setting UI state to shopping")
            state = wasPreviousStatePartial ? .shoppingAfterPartial : .shopping
        }
        if hasErrorState() {
            return
        }
        BobsBuddyInvoker.bobsBuddyDisplay.setState(st: wasPreviousStatePartial ? .gameOverAfterPartial : .gameOver)
        validateSimulationResult()
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
        if LastAttackingHero.isControlled(by: game.player.id) {
            return .win
        } else {
            return .loss
        }
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
            logger.debug("Output is null. Exiting")
            return
        }
        if doNotReport {
            logger.debug("Output was invalidated. Exiting")
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
                "is_duos": "\(game.isBattlegroundsDuosMatch())",
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
        guard let input = input, result == .opponentDied else {
            return false
        }

        return MonoHelper.listItems(obj: input.opponent.heroPowers).any { obj in
            let hp = HeroPowerDataProxy(obj: obj.get())
            return hp.cardId == KelThuzadPowerID
        }
    }
    
    func    isUnknownCard(e: Entity?) -> Bool {
        return e?.card.id == "unknown" || e?.cardId.isEmpty ?? false
    }
    
    func isUnsupportedCard(e: Entity?) -> Bool {
        return e?.card.id == CardIds.NonCollectible.Invalid.ProfessorPutricide_Festergut1 || e?.card.id == CardIds.NonCollectible.Invalid.ProfessorPutricide_Festergut2
    }
    
    func wasHeroPowerActivated(heroPower: Entity?) -> Bool {
        return (heroPower?.has(tag: GameTag.exhausted) ?? false || heroPower?.has(tag: GameTag.bacon_hero_power_activated) ?? false)
    }
    
    static func getOrderedMinions(board: [Entity]) -> [Entity] {
        return board.filter({ $0.isMinion }).map({ $0.copy() }).sorted(by: { $0[GameTag.zone_position] < $1[GameTag.zone_position]})
    }
    
    static func getMinionFromEntity(sim: SimulatorProxy, player: Bool, ent: Entity, attachedEntities: [Entity]) -> MinionProxy {
        let cardId = ent.info.latestCardId
        let minion = sim.minionFactory.createFromCardid(id: cardId, player: player)
        
        minion.primaryRace = Int32(ent[.cardrace])
        minion.baseAttack = Int32(ent[GameTag.atk])
        minion.baseHealth = Int32(ent[GameTag.health])
        minion.taunt = ent.has(tag: GameTag.taunt)
        minion.div = ent.has(tag: GameTag.divine_shield)
        if cardIdsWithCleave.contains(cardId) {
            minion.cleave = true
        }
        minion.poisonous = ent.has(tag: GameTag.poisonous)
        minion.venomous = ent.has(tag: GameTag.venomous)
        minion.windfury = ent.has(tag: GameTag.windfury)
        minion.megaWindfury = ent.has(tag: GameTag.mega_windfury) || cardIdsWithMegaWindfury.contains(cardId)
        minion.stealth = ent.has(tag: .stealth)
        
        let golden = ent.has(tag: GameTag.premium)
        minion.golden = golden
        minion.tier = Int32(ent[GameTag.tech_level])
        minion.reborn = ent.has(tag: GameTag.reborn)
        minion.scriptDataNum1 = Int32(ent[.tag_script_data_num_1])
        minion.scriptDataNum2 = Int32(ent[.tag_script_data_num_2])
        
        let dbfId = ent.card.dbfId
        let m1 = ent[.modular_entity_part_1]
        let m2 = ent[.modular_entity_part_2]
        
        if m1 > 0 && m2 > 0 && (m1 == dbfId || m2 == dbfId) {
            if let modularCard = Cards.by(dbfId: m1 == dbfId ? m2 : m1, collectible: false) {
                minion.attachModularEntity(cardId: modularCard.id)
            }
        }
        
        if golden && (BobsBuddyInvoker.cardIdsWithoutPremiumImplementation.firstIndex(of: cardId) != nil) {
            minion.vanillaAttack *= 2
            minion.vanillaHealth *= 2
        }
        
        for attached in attachedEntities {
            switch attached.cardId {
            case CardIds.NonCollectible.Neutral.RebornRitesTavernBrawl:
                minion.reborn = true
            case CardIds.NonCollectible.Neutral.ReplicatingMenace_ReplicatingMenaceEnchantment:
                minion.addDeathrattle(deathrattle: ReplicatingMenace.deathrattle(golden: false))
            case CardIds.NonCollectible.Neutral.ReplicatingMenace_ReplicatingMenaceEnchantmentTavernBrawl:
                minion.addDeathrattle(deathrattle: ReplicatingMenace.deathrattle(golden: true))
            case BobsBuddyInvoker.WhirringProtector_Normal:
                minion.addAdditionalRally(rally: WhirringProtector.rally(golden: false))
            case BobsBuddyInvoker.WhirringProtector_Golden:
                minion.addAdditionalRally(rally: WhirringProtector.rally(golden: true))
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
            case CardIds.NonCollectible.Neutral.SkyPirateFlagbearer_FlagbearingEnchantment:
                minion.addDeathrattle(deathrattle: Scallywag.deathrattle(golden: false))
            case CardIds.NonCollectible.Neutral.SkyPirateFlagbearer_Flagbearing:
                minion.addDeathrattle(deathrattle: Scallywag.deathrattle(golden: true))
            case CardIds.NonCollectible.Neutral.Leapfrogger_LeapfrogginEnchantment:
                minion.addDeathrattle(deathrattle: Leapfrogger.deathrattle(golden: false))
            case CardIds.NonCollectible.Neutral.Leapfrogger_Leapfroggin:
                minion.addDeathrattle(deathrattle: Leapfrogger.deathrattle(golden: true))
            case CardIds.NonCollectible.Neutral.RustyTrident_TridentsTreasureEnchantment:
                minion.addDeathrattle(deathrattle: RustyTrident.deathrattle())
            case CardIds.NonCollectible.Neutral.HoggyBank_GemInTheBankEnchantment:
                minion.addDeathrattle(deathrattle: HoggyBank.deathrattle())
            case CardIds.NonCollectible.Neutral.JarredFrostling_FrostyGlobeEnchantment:
                minion.addDeathrattle(deathrattle: JarredFrostling.deathrattle())
            case CardIds.NonCollectible.Neutral.BloodGem2:
                let atk = attached[.tag_script_data_num_1]
                let health = attached[.tag_script_data_num_2]
                minion.setBloodGemStats(atk, health)
            default:
                if attached.card.type == .enchantment && !attached.cardId.isEmpty {
                    let enchantment = sim.enchantmentFactory.create(cardId: attached.cardId, controlledByPlayer: minion.controlledByPlayer)
                    if enchantment.get() != nil {
                        enchantment.scriptDataNum1 = Int32(attached[.tag_script_data_num_1])
                        enchantment.scriptDataNum2 = Int32(attached[.tag_script_data_num_2])
                        minion.attachEnchantment(enchantment: enchantment)
                    }
                }
            }
        }
        
        minion.gameId = Int32(ent.id)
        
        return minion
    }
    
    static func getObjectiveFromEntity(factory: ObjectiveFactoryProxy, player: Bool, entity: Entity) -> ObjectiveProxy {
        let objective = factory.create(cardId: entity.cardId, controlledByPlayer: player)
        let scriptDataNum1 = entity[.tag_script_data_num_1]
        let scriptDataNum2 = objective.scriptDataNum2
        if scriptDataNum1 > 0 {
            objective.scriptDataNum1 = Int32(scriptDataNum1)
        }
        if scriptDataNum1 > 0 {
            objective.scriptDataNum2 = Int32(scriptDataNum2)
        }
        return objective
    }
    
    static func getTrinketFromEntity(factory: TrinketFactoryProxy, player: Bool, entity: Entity) -> TrinketProxy {
        let trinket = factory.create(id: entity.cardId, friendly: player)
        let scriptDataNum1 = entity[.tag_script_data_num_1]
        let scriptDataNum2 = trinket.scriptDataNum2
        if scriptDataNum1 > 0 {
            trinket.scriptDataNum1 = Int32(scriptDataNum1)
        }
        if scriptDataNum2 > 0 {
            trinket.scriptDataNum2 = Int32(scriptDataNum2)
        }
        return trinket
    }
    
    func getAttachedEntities(entityId: Int) -> [Entity] {
        return game.entities.values.filter({ $0.isAttachedTo(entityId: entityId) && ($0.isInPlay || $0.isInSetAside || $0.isInGraveyard) }).map({ $0.copy() })
    }
    
    private func setupInputPlayer(simulator: SimulatorProxy, gamePlayer: Player, inputPlayer: PlayerProxy, playerEntity: Entity?, friendly: Bool) throws {
        let playerGameHero = gamePlayer.hero

        guard let playerEntity else {
            throw "\(friendly ? "Player" : "Opponent") Entity could not be found. Exiting."
        }
        
        for entity in gamePlayer.board where !entity.cardId.isBlank {
            if isUnknownCard(e: entity) {
                errorState = .unknownCards
                throw "Board has unknown cards. Exiting."
            }
            
            // SupportedCards.VerifyCardIsSupported currently only works with TECH_LEVEL > 0.
            // TODO: as this is implemented in BB and would require a call via Mono
            
            if isUnsupportedCard(e: entity) {
                errorState = .unsupportedCards
                throw "Board has unsupported cards. Exiting."
            }
        }
        
        guard let playerGameHero else {
            throw "Hero(es) could not be found. Exiting."
        }
                
        inputPlayer.health = Int32(playerGameHero.health + playerGameHero[.armor])
        
        if !friendly && inputPlayer.health <= 0 {
            inputPlayer.health = 1000
        }

        inputPlayer.damageTaken = Int32(playerGameHero[GameTag.damage])
        inputPlayer.tier = Int32(playerGameHero[GameTag.player_tech_level])
        
        let playerHeroPowers = gamePlayer.board.filter({ $0.isHeroPower }).take(2)
        
        for heroPower in playerHeroPowers {
            var pHpData = heroPower[.tag_script_data_num_1]
            let pHpData2 = heroPower[.tag_script_data_num_2]
            let pHpData3 = heroPower[.tag_script_data_num_3]
            var pHpAttachedMinion: MinionProxy?
            
            if heroPower.cardId == CardIds.NonCollectible.Neutral.TeronGorefiend_RapidReanimation {
                let minionsInPlay = game.player.board.filter { e in e.isMinion && e.isControlled(by: game.player.id)}.compactMap { x in x.id }
                let attachedToEntityId = game.player.playerEntities
                    .filter { x in x.cardId == CardIds.NonCollectible.Neutral.TeronGorefiend_ImpendingDeath && x.isInPlay }
                    .compactMap { x in x[.attached] }
                    .first { x in minionsInPlay.any { y in y == x } } ?? 0
                if attachedToEntityId > 0 {
                    pHpData = attachedToEntityId
                }
            }
            
            if heroPower.cardId == CardIds.NonCollectible.Neutral.FlobbidinousFloop_GloriousGloop {
                let minionsInPlay = gamePlayer.board.filter { e in e.isMinion && e.isControlled(by: gamePlayer.id) }.compactMap { x in x.id }
                let attachedToEntityId = gamePlayer.playerEntities.filter { x in x.cardId == CardIds.NonCollectible.Neutral.FlobbidinousFloop_InTheGloop && (!friendly || (x.isInPlay && friendly)) }.compactMap { x in x[.attached] }.first { x in minionsInPlay.any { y in y == x } } ?? 0
                if attachedToEntityId > 0 {
                    pHpData = attachedToEntityId
                }
            }
            
            if heroPower.cardId == CardIds.NonCollectible.Neutral.TavishStormpike_LockAndLoad {
                if !friendly {
                    errorState = .unknownCards
                    throw "Board has unsupported hero power. Exiting."
                }
                let attachedEntityId = heroPower[.tag_script_data_ent_1]
                if let attachedEntity = gamePlayer.setAside.first(where: { e in e.id == attachedEntityId }) {
                    pHpAttachedMinion = BobsBuddyInvoker.getMinionFromEntity(sim: simulator, player: friendly, ent: attachedEntity, attachedEntities: getAttachedEntities(entityId: attachedEntityId))
                }
            }
            inputPlayer.addHeroPower(heroPowerCardId: heroPower.cardId, friendly: friendly, isActivated: wasHeroPowerActivated(heroPower: heroPower), data: Int32(pHpData), data2: Int32(pHpData2), data3: Int32(pHpData3), attachedMinion: pHpAttachedMinion ?? MonoHandle())
        }

        let playerQuests = inputPlayer.quests
        for quest in gamePlayer.quests {
            let rewardDbfId = quest[.quest_reward_database_id]
            let reward = Cards.by(dbfId: rewardDbfId, collectible: false)
            let questData = QuestDataProxy()
            questData.questProgress = Int32(quest[.quest_progress])
            questData.questProgressTotal = Int32(quest[.quest_progress_total])
            questData.questCardId = quest.cardId
            questData.rewardCardId = reward?.id ?? ""
            MonoHelper.addToList(list: playerQuests, element: questData)
        }

        for reward in gamePlayer.questRewards {
            let questData = QuestDataProxy()
            questData.questProgress = Int32(0)
            questData.questProgressTotal = Int32(0)
            questData.questCardId = ""
            questData.rewardCardId = reward.info.latestCardId
            questData.rewardScriptDataNum1 = Int32(reward[.tag_script_data_num_1])
            questData.rewardScriptDataNum2 = Int32(reward[.tag_script_data_num_2])
            MonoHelper.addToList(list: playerQuests, element: questData)
        }
        for trinket in gamePlayer.trinkets {
            MonoHelper.addToList(list: inputPlayer.trinkets, element: BobsBuddyInvoker.getTrinketFromEntity(factory: simulator.trinketFactory, player: friendly, entity: trinket))
        }
        let playerObjectives = inputPlayer.objectives
        for objective in game.player.objectives {
            // TODO: [Duos] Check if friendly translates to player correctly
            MonoHelper.addToList(list: playerObjectives, element: BobsBuddyInvoker.getObjectiveFromEntity(factory: simulator.objectiveFactory, player: friendly, entity: objective))
        }
        
        let playerSide = BobsBuddyInvoker.getOrderedMinions(board: gamePlayer.board).filter { e in e.isControlled(by: gamePlayer.id) }.map { e in BobsBuddyInvoker.getMinionFromEntity(sim: simulator, player: friendly, ent: e, attachedEntities: getAttachedEntities(entityId: e.id))}
        let inputPlayerSide = inputPlayer.side
        for m in playerSide {
            MonoHelper.addToList(list: inputPlayerSide, element: m)
        }
        
        if friendly {
            let target = inputPlayer.secrets
            MonoHelper.listClear(obj: target)
            
            inputPlayer.setSecrets(secrets: gamePlayer.secrets.compactMap { s in s.card.dbfId })

            let playerHand = inputPlayer.hand
            
            for e in gamePlayer.hand {
                if e.isMinion {
                    let minionEntity = MinionCardEntityProxy(minion: BobsBuddyInvoker.getMinionFromEntity(sim: simulator, player: true, ent: e, attachedEntities: getAttachedEntities(entityId: e.id)), simulator: simulator)
                    minionEntity.canSummon = !e.has(tag: .literally_unplayable)
                    MonoHelper.addToList(list: playerHand, element: minionEntity)
                } else if e.cardId == CardIds.NonCollectible.Neutral.BloodGem1 {
                    MonoHelper.addToList(list: playerHand, element: BloodGemProxy(simulator: simulator))
                } else if e.isSpell {
                    MonoHelper.addToList(list: playerHand, element: SpellCardEntityProxy(simulator: simulator))
                } else {
                    MonoHelper.addToList(list: playerHand, element: CardEntityProxy(id: e.cardId, simulator: simulator))
                }
            }
        } else {
            let secrets = gamePlayer.secrets
            opponentSecrets = secrets
            var secretsToAdd = [Int]()
            var seen = Set<Int>()
            for dbfid in secrets.compactMap({ x in
                !x.cardId.isEmpty ? x.card.dbfId : nil }) {
                if dbfid == 0 {
                    secretsToAdd.append(0)
                } else if !seen.contains(dbfid) {
                    secretsToAdd.append(dbfid)
                    seen.insert(dbfid)
                }
            }
            inputPlayer.setSecrets(secrets: secretsToAdd)

            self.opponentHand = gamePlayer.hand
            let opponentHand = inputPlayer.hand
            MonoHelper.listClear(obj: opponentHand)
            
            let opponentHandEntities = getOpponentHandEntities(simulator: simulator)
            for e in opponentHandEntities {
                MonoHelper.addToList(list: opponentHand, element: e)
            }
        }
        
        let playerAttached = getAttachedEntities(entityId: playerEntity.id)
        let pEternalLegion = playerAttached.first { x in x.cardId == CardIds.NonCollectible.Neutral.EternalKnight_EternalKnightPlayerEnchant }
        if let pEternalLegion {
            inputPlayer.eternalKnightCounter = Int32(pEternalLegion[.tag_script_data_num_1])
        }
        let pUndeadBonus = playerAttached.first { x in x.cardId == CardIds.NonCollectible.Neutral.NerubianDeathswarmer_UndeadBonusAttackPlayerEnchantDnt }
        if let pUndeadBonus {
            inputPlayer.undeadAttackBonus = Int32(pUndeadBonus[.tag_script_data_num_1])
        }
        
        if let pAncestralAutomaton = playerAttached.first(where: { x in x.cardId == CardIds.Invalid.AncestralAutomaton_AncestralAutomatonPlayerEnchantDnt }) {
            inputPlayer.ancestralAutomatonCounter = Int32( pAncestralAutomaton[.tag_script_data_num_1])
        }
        if let pBeetle = playerAttached.first(where: { x in x.cardId == CardIds.NonCollectible.Neutral.RunedProgenitor_BeetleArmyPlayerEnchantDnt }) {
            inputPlayer.beetlesAtkBuff = Int32(pBeetle[.tag_script_data_num_1])
            inputPlayer.beetlesHealthBuff = Int32(pBeetle[.tag_script_data_num_2])
        }
        inputPlayer.elementalPlayCounter = Int32(game.playerEntity?[.gametag_2878] ?? 0)

        logger.info("pEternal=\(inputPlayer.eternalKnightCounter), pUndead=\(inputPlayer.undeadAttackBonus), pElemental=\(inputPlayer.elementalPlayCounter), friendly=\(friendly)")

        inputPlayer.piratesSummonCounter = Int32(game.playerEntity?[.gametag_2358] ?? 0)
        
        inputPlayer.beastsSummonCounter = Int32(game.playerEntity?[.gametag_3962] ?? 0)
        
        inputPlayer.friendlyMinionsDeadLastCombatCounter = Int32(game.playerEntity?[.gametag_2717] ?? 0)
        
        inputPlayer.battlecryCounter = Int32(game.playerEntity?[.gametag_3236] ?? 0)
        
        logger.info("pPirates=\(inputPlayer.piratesSummonCounter), pBeasts=\(inputPlayer.beastsSummonCounter), pDeadLastCombat=\(inputPlayer.friendlyMinionsDeadLastCombatCounter), pBattlecry=\(inputPlayer.battlecryCounter), friendly=\(friendly)")
        
        inputPlayer.bloodGemAtkBuff = Int32(playerEntity[.bacon_bloodgembuffatkvalue])
        inputPlayer.bloodGemHealthBuff = Int32(playerEntity[.bacon_bloodgembuffhealthvalue])
        
        logger.info("pBloodGem=+\(inputPlayer.bloodGemAtkBuff)/+\(inputPlayer.bloodGemHealthBuff), friendly=\(friendly)")
    }

    func snapshotBoardState(turn: Int) {
        logger.debug("Snapshotting board state...")
        LastAttackingHero = nil
        
        let simulator = SimulatorProxy()
        let input = InputProxy()
        
        guard let gameEntity = game.gameEntity else {
            logger.debug("GameEntity could not be found. Exiting")
            return
        }
                
        guard let races = game.availableRaces else {
            errorState = .unknownCards
            logger.error("Game has no available races. Exiting")
            return
        }
        
        input.addAvailableRaces(races: races)

        if gameEntity[.bacon_combat_damage_cap_enabled] > 0 {
            input.damageCap = Int32(gameEntity[.bacon_combat_damage_cap])
        }
        
        do {
            if self.input == nil {
                try setupInputPlayer(simulator: simulator, gamePlayer: game.player, inputPlayer: input.player, playerEntity: game.playerEntity, friendly: true)
                try setupInputPlayer(simulator: simulator, gamePlayer: game.opponent, inputPlayer: input.opponent, playerEntity: game.opponentEntity, friendly: false)
                duosInputPlayer = input.player
                duosInputOpponent = input.opponent
                duosInputPlayerTeammate = nil
                duosInputOpponentTeammate = nil
            } else {
                if game.duosWasPlayerHeroModified && duosInputPlayerTeammate == nil && input.playerTeammate.get() != nil {
                    try setupInputPlayer(simulator: simulator, gamePlayer: game.player, inputPlayer: input.playerTeammate, playerEntity: game.playerEntity, friendly: true)
                    duosInputPlayerTeammate = input.playerTeammate
                }
                if game.duosWasOpponentHeroModified && duosInputOpponentTeammate == nil && input.opponentTeammate.get() != nil {
                    try setupInputPlayer(simulator: simulator, gamePlayer: game.opponent, inputPlayer: input.opponentTeammate, playerEntity: game.opponentEntity, friendly: false)
                    duosInputOpponentTeammate = input.opponentTeammate
                }
                if game.isBattlegroundsDuosMatch() {
                    input.isDuos = true
                    input.player = duosInputPlayer
                    input.opponent = duosInputOpponent
                    input.playerTeammate = duosInputPlayerTeammate ?? input.playerTeammate
                    input.opponentTeammate = duosInputOpponentTeammate ?? input.opponentTeammate
                }
            }
        } catch {
            logger.error(error)
            return
        }
                        
        let anomalyDbfId = BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: game.gameEntity)
        if let anomalyCardId = Cards.by(dbfId: anomalyDbfId, collectible: false)?.id {
            input.anomaly = simulator.anomalyFactory.create(id: anomalyCardId)
        }
        
        input.setTurn(value: Int32(turn))
                
        self.input = input
        self._turn = turn
        
        logger.debug("Successfully snapshotted board state")
    }
    
    private var reRunCount = 0
    
    func tryRerun() {
        reRunCount += 1
        if reRunCount <= 11 {
            logger.debug("Input changed, re-running simulation! (\(reRunCount))")
            if shouldRun() {
                let expandAfterError = errorState == .none && Settings.showBobsBuddyDuringCombat
                errorState = .none
                BobsBuddyInvoker.bobsBuddyDisplay.setErrorState(error: .none, show: expandAfterError)
                output = nil
                _ = runAndDisplaySimulationAsync()
            }
        } else {
            logger.debug("Input changed, but the simulation already re-ran ten times")
        }
    }
    
    func updateOpponentHand(entity: Entity, copy: Entity) {
        guard let input, state != .combat  else {
            return
        }
        
        // Only allow feathermane and Flighty Scout for now.
        if copy.cardId != CardIds.NonCollectible.Neutral.FreeFlyingFeathermane && copy.cardId != CardIds.NonCollectible.Neutral.FreeFlyingFeathermane_FreeFlyingFeathermane && copy.cardId != CardIds.NonCollectible.Neutral.FlightyScout && copy.cardId != CardIds.NonCollectible.Neutral.FlightyScout_FlightyScout {
            return
        }
        
        opponentHandMap[entity] = copy
        
        // Wait for attached entities to be logged. This should happen at the exact same timestamp.
        //await _game.GameTime.WaitForDuration(1);
        let simulator = SimulatorProxy()
        let entities = getOpponentHandEntities(simulator: simulator)
        if let _class = MinionCardEntityProxy._class, entities.filter({ x in MonoHelper.isInstance(obj: x, klass: _class) }).count <= MonoHelper.listItems(obj: input.opponent.hand).filter({ x in MonoHelper.isInstance(obj: x, klass: _class) }).count {
            return
        }

        MonoHelper.listClear(obj: input.opponent.hand)
        for ent in entities {
            MonoHelper.addToList(list: input.opponent.hand, element: ent)
        }
        
        tryRerun()
    }
    
    func updateOpponentSecret(entity: Entity) {
        guard let input, state == .combat && game.isBattlegroundsDuosMatch() else {
            return
        }
        var secretsToAdd = [Int?]()
        var seen = Set<Int>()
        for dbfid in opponentSecrets.compactMap({ x in
            !x.cardId.isEmpty ? x.card.dbfId : nil }) {
            if dbfid == 0 {
                secretsToAdd.append(nil)
            } else if !seen.contains(dbfid) {
                secretsToAdd.append(dbfid)
                seen.insert(dbfid)
            }
        }
        let oppSecrets = input.opponent.secrets
        MonoHelper.listClear(obj: oppSecrets)
        for secret in secretsToAdd {
            input.addSecretFromDbfid(id: secret, target: oppSecrets)
        }
        tryRerun()
    }

    private func getOpponentHandEntities(simulator: SimulatorProxy) -> [MonoHandle] {
        var result = [MonoHandle]()
        for _e in opponentHand {
            let e = opponentHandMap[_e] ?? _e
            if e.isMinion {
                let attached = getAttachedEntities(entityId: e.id)
                let minion = MinionCardEntityProxy(minion: BobsBuddyInvoker.getMinionFromEntity(sim: simulator, player: false, ent: e, attachedEntities: attached), simulator: simulator)
                minion.canSummon = !e.has(tag: .literally_unplayable)
                result.append(minion)
            } else if e.cardId == CardIds.NonCollectible.Neutral.BloodGem1 {
                result.append(BloodGemProxy(simulator: simulator))
            } else if e.isSpell {
                result.append(SpellCardEntityProxy(simulator: simulator))
            } else if !e.cardId.isEmpty {
                result.append(CardEntityProxy(id: e.cardId, simulator: simulator)) // Not Unknown
            } else {
                result.append(UnknownCardEntityProxy(simulator: simulator))
            }
        }
        return result
    }
}
