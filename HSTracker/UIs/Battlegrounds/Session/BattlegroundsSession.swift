//
//  BattlegroundsSession.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/12/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsSession: OverWindowController {
    @IBOutlet weak var outerBox: NSBox!
    
    @IBOutlet weak var tribesSection: NSStackView!
    @IBOutlet weak var tribe1: BattlegroundsTribe!
    @IBOutlet weak var tribe2: BattlegroundsTribe!
    @IBOutlet weak var tribe3: BattlegroundsTribe!
    @IBOutlet weak var tribe4: BattlegroundsTribe!
    @IBOutlet weak var tribe5: BattlegroundsTribe!
    @IBOutlet weak var waitingForNext: NSTextField!
    
    @IBOutlet weak var mmrSection: NSStackView!
    @IBOutlet weak var mmrLabelA: NSTextField!
    @IBOutlet weak var mmrFieldA: NSTextField!
    @IBOutlet weak var mmrLabelB: NSTextField!
    @IBOutlet weak var mmrFieldB: NSTextField!
    
    @IBOutlet weak var latestGamesSection: NSStackView!
    @IBOutlet weak var noGamesSection: NSView!
    @IBOutlet weak var lastGames: NSStackView!
    
    @IBOutlet weak var compositions: NSStackView!
    @IBOutlet weak var compositionsItems: NSStackView!
    @IBOutlet weak var compositionsWaiting: NSTextField!
    @IBOutlet weak var compositionsError: NSTextField!
    
    @IBOutlet weak var sessionPanel: NSStackView!
    
    private var sessionGames = [BattlegroundsLastGames.GameItem]()
    
    var visibility = false
    
    @objc dynamic var minionsTypeHeader = ""
    
    private var _battlegroundsGameMode: SelectedBattlegroundsGameMode = .unknown
    
    private let _updateCompStatsSemaphore = UnfairLock()
    
    var battlegroundsGameMode: SelectedBattlegroundsGameMode {
        get {
            return _battlegroundsGameMode
        }
        set {
            let modified = _battlegroundsGameMode != newValue
            _battlegroundsGameMode = newValue
            if modified {
                DispatchQueue.main.async {
                    self.updateSectionsVisibilities()
                    if #available(macOS 10.15, *) {
                        Task.detached {
                            await self.updateCompositionStatsVisibility()
                        }
                    }
                    self.update()
                    self.updateScaling()
                }
            }
        }
    }
    
    func updateScaling() {
        guard let window else {
            return
        }
        let bounds = sessionPanel.bounds
        let scale = Settings.battlegroundsSessionScaling
        let sw = bounds.width * scale
        let sh = bounds.height * scale
        outerBox.frame = NSRect(x: 0, y: window.frame.height - sh, width: sw, height: sh)
        outerBox.bounds = bounds
        outerBox.needsDisplay = true
    }
    
    func onGameStart() {
        if AppDelegate.instance().coreManager.game.spectator {
            return
        }
        DispatchQueue.main.async {
            self.showAvailableMinionTypes()
            self.update()
            self.updateScaling()
        }
    }
    
    func onGameEnd(gameStats: InternalGameStats) {
        if AppDelegate.instance().coreManager.game.spectator {
            return
        }
        DispatchQueue.main.async {
            self.hideAvailableMinionTypes()
            self.update()
            self.updateScaling()
        }
    }
    
    @MainActor
    func show() {
        if window?.occlusionState.contains(.visible) ?? false || AppDelegate.instance().coreManager.game.spectator {
            return
        }
        updateSectionsVisibilities()
        update()
        updateScaling()
    }
    
    private func showAvailableMinionTypes() {
        tribe1.isHidden = false
        tribe2.isHidden = false
        tribe3.isHidden = false
        tribe4.isHidden = false
        tribe5.isHidden = false
        waitingForNext.isHidden = true
    }
    
    private func hideAvailableMinionTypes() {
        tribe1.isHidden = true
        tribe2.isHidden = true
        tribe3.isHidden = true
        tribe4.isHidden = true
        tribe5.isHidden = true
        waitingForNext.isHidden = false
    }
    
    private var isDuos: Bool {
        let game = AppDelegate.instance().coreManager.game
        return game.isInMenu ? battlegroundsGameMode == .duos : game.isBattlegroundsDuosMatch()
    }
    
    func updateSectionsVisibilities() {
        tribesSection.isHidden = !Settings.showMinionsSection
        compositions.isHidden = !Settings.showBattlegroundsTier7SessionCompStats
        mmrSection.isHidden = !Settings.showMMR
        latestGamesSection.isHidden = !Settings.showLatestGames
    }
    
    func updateMinionsTypeLabel() {
        minionsTypeHeader = String.localizedString(Settings.showMinionTypes == 0 ? "Battlegrounds_Session_Header_Label_Minions_Banned" : "Battlegrounds_Session_Header_Label_Minions_Available", comment: "")
    }

    func update() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.update()
            }
            return
        }
        let game = AppDelegate.instance().coreManager.game
        let showAvailable = Settings.showMinionTypes != 0
        let races = showAvailable ? game.availableRaces : game.unavailableRaces
        updateMinionsTypeLabel()
        if !game.gameEnded, let races, races.count >= 5 && races.count != Database.battlegroundRaces.count {
            logger.debug("Updating with \(races)")
            let sorted = races.sorted(by: { (a, b) in String.localizedString(a.rawValue, comment: "") < String.localizedString(b.rawValue, comment: "") })
            tribe1.setRace(newRace: sorted[0], showAvailable)
            tribe2.setRace(newRace: sorted[1], showAvailable)
            tribe3.setRace(newRace: sorted[2], showAvailable)
            tribe1.isHidden = false
            tribe2.isHidden = false
            tribe3.isHidden = false
            if sorted.count > 3 {
                tribe4.setRace(newRace: sorted[3], showAvailable)
                tribe4.isHidden = false
            } else {
                tribe4.isHidden = true
            }
            if sorted.count > 4 {
                tribe5.setRace(newRace: sorted[4], showAvailable)
                tribe5.isHidden = false
            } else {
                tribe5.isHidden = true
            }
            var font = tribe1.tribeLabel.font
            var minSize = tribe1.tribeLabel.font?.pointSize ?? 13.0
            if tribe2.tribeLabel.font?.pointSize ?? 13.0 < minSize {
                font = tribe2.tribeLabel.font
                minSize = font?.pointSize ?? 13.0
            }
            if tribe3.tribeLabel.font?.pointSize ?? 13.0 < minSize {
                font = tribe3.tribeLabel.font
                minSize = font?.pointSize ?? 13.0
            }
            if tribe4.tribeLabel.font?.pointSize ?? 13.0 < minSize {
                font = tribe4.tribeLabel.font
                minSize = font?.pointSize ?? 13.0
            }
            if tribe5.tribeLabel.font?.pointSize ?? 13.0 < minSize {
                font = tribe5.tribeLabel.font
                minSize = font?.pointSize ?? 13.0
            }
            tribe1.tribeLabel.font = font
            tribe2.tribeLabel.font = font
            tribe3.tribeLabel.font = font
            tribe4.tribeLabel.font = font
            tribe5.tribeLabel.font = font
            showAvailableMinionTypes()
        } else {
            logger.debug("Not enough races found: \(races ?? [Race]())")
            hideAvailableMinionTypes()
        }
        
        // Update method might be called multiple times.
        // We need to prevent multiple calls to UpdateCompositionStatsIfNeeded to happen at the same time.
        // This also ensures only one API call is made.
        
        if #available(macOS 10.15.0, *) {
            _updateCompStatsSemaphore.lock()
            defer {
                _updateCompStatsSemaphore.unlock()
            }
            Task.init {
                await updateCompositionStatsIfNeeded()
            }
        }
                
        let firstGame = updateLatestGames()
        
        let rating = isDuos ? game.battlegroundsRatingInfo?.duosRating.intValue ?? 0 :  game.battlegroundsRatingInfo?.rating.intValue ?? 0
        let ratingStart = firstGame?.rating ?? rating
        
        if Settings.showMMRStartCurrent {
            mmrLabelA.stringValue = String.localizedString("Start", comment: "")
            mmrFieldA.stringValue = formatRating(mmr: ratingStart)
            mmrLabelB.stringValue = String.localizedString("Current", comment: "")
            mmrFieldB.stringValue = formatRating(mmr: rating)
            mmrFieldB.textColor = NSColor.white
        } else {
            mmrLabelA.stringValue = String.localizedString("Current", comment: "")
            mmrFieldA.stringValue = formatRating(mmr: rating)
            mmrLabelB.stringValue = String.localizedString("Change", comment: "")
            let mmrDelta = rating - ratingStart
            mmrFieldB.stringValue = "\(mmrDelta > 0 ? "+" : "")\(formatRating(mmr: mmrDelta))"
            mmrFieldB.textColor = mmrDelta == 0 ? NSColor.white : mmrDelta > 0 ? BattlegroundsGameView.mmrPositive : BattlegroundsGameView.mmrNegative
        }
        
        sessionPanel.needsLayout = true
    }
    
    @available(macOS 10.15, *)
    private func updateCompositionStatsVisibility() async {
        let userOwnsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
        
        if let acc = MirrorHelper.getAccountId() {
            if !userOwnsTier7 {
                await Tier7Trial.update(hi: acc.hi.int64Value, lo: acc.lo.int64Value)
            }
        }
        if isDuos || !Settings.showBattlegroundsTier7SessionCompStats {
            availableCompStatsSectionVisibility = false
        } else {
            availableCompStatsSectionVisibility = userOwnsTier7 || Tier7Trial.remainingTrials ?? 0 > 0 || compositionStats != nil
        }
    }
    
    private func setBattlegroundsCompositionStatsViewModel(_ compData: [BattlegroundsCompStats.LobbyComp]) {
        for subview in compositionsItems.subviews.reversed() where subview as? BattlegroundsCompositionStatsRow != nil {
            subview.removeFromSuperview()
        }
        
        let compStatsOrdered = compData.sorted(by: { (a, b) -> Bool in a.popularity > b.popularity })
        
        if compStatsOrdered.count > 0 {
            let max = max(ceil(compStatsOrdered[0].popularity), 40.0)
            
            let vms = compStatsOrdered.filter { comp in comp.id != -1 && comp.name != nil }.compactMap { comp in
                let minionDbfId = comp.key_minions_top3 == nil || comp.key_minions_top3?.count == 0 ? 59201 : comp.key_minions_top3?[0] ?? 59201
                return BattlegroundsCompositionStatsRowViewModel(comp.name ?? "", minionDbfId, comp.popularity, comp.avg_final_placement, max)
            }
            
            for vm in vms {
                let comp = BattlegroundsCompositionStatsRow(viewModel: vm)
                compositionsItems.addArrangedSubview(comp)
            }
            
            compositionStats = vms
        }
    }
    
    @available(macOS 10.15.0, *)
    private func getBattlegroundsCompStats() async throws -> BattlegroundsCompStats? {
        if isDuos {
            return nil
        }
        
        let game = AppDelegate.instance().coreManager.game
        
        if game.spectator {
            return nil
        }
        
        if !Settings.enableTier7Overlay {
            return nil
        }
        
        if RemoteConfig.data?.tier7?.disabled ?? false {
            // FIXME
            return nil
        }
        
        let userOwnsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
        
        var counter = 0
        while game.availableRaces == nil && counter < 5 {
            await Task.sleep(milliseconds: 500)
            counter += 1
        }
        guard let availableRaces = game.availableRaces else {
            throw CompositionStatsException("Unable to get available races")
        }
        
        let compParams = BattlegroundsCompStatsParams(minion_types: availableRaces.compactMap { x in Race.allCases.firstIndex(of: x) }, game_language: Settings.hearthstoneLanguage?.rawValue ?? "enUS")
        
        var token: String?
        
        if !userOwnsTier7 {
            let acc = MirrorHelper.getAccountId()
            
            if let acc {
                token = await Tier7Trial.activate(hi: acc.hi.int64Value, lo: acc.lo.int64Value)
                
                if token == nil {
                    throw CompositionStatsException("Unable to get trial token")
                }
            }
        }
        
        // At this point the user either owns tier7 or has an active trial!

        var compStats: BattlegroundsCompStats?
        if let token {
            compStats = await HSReplayAPI.getTier7CompStats(token: token, parameters: compParams)
        } else {
            compStats = await HSReplayAPI.getTier7CompStats(parameters: compParams)
        }

        if compStats == nil || compStats?.data.first_place_comps_lobby_races.count == 0 {
            throw CompositionStatsException("Invalid server response")
        }

        return compStats
    }
    
    private var compositionStats: [BattlegroundsCompositionStatsRowViewModel]?
    private var compStatsBodyVisibility = false
    private var compStatsWaitingMsgVisibility = false
    private var compStatsErrorVisibility = false
    private var availableCompStatsSectionVisibility = false
    
    @MainActor
    private func updateCompositionsVisibilities() {
        compositionsWaiting.isHidden = !compStatsWaitingMsgVisibility
        compositionsError.isHidden = !compStatsErrorVisibility
        compositionsItems.isHidden = !compStatsBodyVisibility
    }
    
    @MainActor
    private func clearCompositionStats() {
        compositionStats = nil
        for subview in compositionsItems.subviews.reversed() {
            subview.removeFromSuperview()
        }
        compStatsBodyVisibility = false
        compStatsWaitingMsgVisibility = true
        compStatsErrorVisibility = false
        
        updateCompositionsVisibilities()
    }
    
    @MainActor
    private func showCompositionStats() {
        compStatsBodyVisibility = true
        compStatsWaitingMsgVisibility = false
        compStatsErrorVisibility = false
        
        updateCompositionsVisibilities()
        
        AppDelegate.instance().coreManager.game.updateBattlegroundsOverlays()
    }
    
    @available(macOS 10.15.0, *)
    private func updateCompositionStatsIfNeeded() async {
        let game = AppDelegate.instance().coreManager.game
        
        if game.currentMode != .gameplay || SceneHandler.scene != .gameplay {
            clearCompositionStats()
            return
        }
        
        // Ensures data was already fetched and no more API calls are needed
        if ((compositionStats != nil && compositionStats?.count != 0) || compStatsErrorVisibility)  && (game.currentMode == .gameplay || SceneHandler.scene == .gameplay) {
            return
        }

        await trySetCompStats()
    }
    
    @available(macOS 10.15.0, *)
    private func trySetCompStats() async {
        do {
            if let compStats = try await getBattlegroundsCompStats() {
                setBattlegroundsCompositionStatsViewModel(compStats.data.first_place_comps_lobby_races)
                showCompositionStats()
            }
        } catch {
            handleCompStatsError(error)
        }
    }
    
    func hideCompStatsOnError() {
        if compStatsErrorVisibility {
            availableCompStatsSectionVisibility = false
            DispatchQueue.main.async {
                self.updateCompositionsVisibilities()
            }
        }
    }

    private func handleCompStatsError(_ error: Error) {
        logger.error(error)
        
        let game = AppDelegate.instance().coreManager.game
        
        let beforeHeroPicked = (game.gameEntity?[GameTag.step] ?? 0) <= Step.begin_mulligan.rawValue
        if !beforeHeroPicked {
            if #available(macOS 10.15, *) {
                Task.detached {
                    // Ensure update after 20 seconds
                    await Task.sleep(milliseconds: 20_000)
                    await self.hideCompStatsOnError()
                }
            }
        }

        compStatsErrorVisibility = true
        compStatsBodyVisibility = false
        compStatsWaitingMsgVisibility = false
    }

    private func updateLatestGames() -> BattlegroundsLastGames.GameItem? {
        sessionGames.removeAll()
        let sortedGames = BattlegroundsLastGames.instance.getPlayerGames(duos: isDuos).sorted(by: { (a, b) in a.startTime < b.startTime })
        deleteOldGames(games: sortedGames)
        sessionGames = getSessionGames(sortedGames: sortedGames)
        let firstGame = sessionGames.first
        if sessionGames.count > 10 {
            sessionGames.removeSubrange(0 ..< sessionGames.count - 10)
        }
        sessionGames = sessionGames.sorted(by: { (a, b) in a.startTime > b.startTime })
        for subview in lastGames.subviews.reversed() where subview as? BattlegroundsGameView != nil {
            subview.removeFromSuperview()
        }
        for game in sessionGames {
            let gameView = BattlegroundsGameView(frame: NSRect(x: 0, y: 0, width: 200, height: 34))
            gameView.update(game: game)
            self.lastGames.addArrangedSubview(gameView)
        }
        
        if sessionGames.count == 0 {
            noGamesSection.isHidden = false
            lastGames.isHidden = true
        } else {
            noGamesSection.isHidden = true
            lastGames.isHidden = false
        }
        return firstGame
    }
    
    private func getSessionGames(sortedGames: [BattlegroundsLastGames.GameItem]) -> [BattlegroundsLastGames.GameItem] {
        var sessionStartTime: Date?
        var previousGameEndTime: Date?
        var previousGameRatingAfter = 0
        for g in sortedGames {
            if let previousGameEndTime = previousGameEndTime {
                let gStartTime = g.startTime
                let ts = gStartTime.timeIntervalSince(previousGameEndTime)
                let diffMMR = g.rating - previousGameRatingAfter
                let ratingReset = g.rating < 500 && diffMMR < -500
                
                if ts / 3600 >= 6 || ratingReset {
                    sessionStartTime = gStartTime
                }
            }
            previousGameEndTime = g.endTime
            previousGameRatingAfter = g.ratingAfter
        }
        
        var sessionGames = [BattlegroundsLastGames.GameItem]()
        if let sessionStartTime = sessionStartTime {
            sessionGames = sortedGames.filter({ x in x.startTime >= sessionStartTime })
        } else {
            sessionGames = sortedGames
        }
        if sessionGames.count > 0, let lastGame = sessionGames.last {
            // Check for MMR reset on last game
            var ratingResetAfterLastGame = false
            if let currentMMR = AppDelegate.instance().coreManager.game.battlegroundsRatingInfo?.rating.intValue {
                let sessionLastMMR = lastGame.ratingAfter
                ratingResetAfterLastGame = currentMMR < 500 && currentMMR - sessionLastMMR < -500
            }
            if Date().timeIntervalSince(lastGame.endTime) >= 6 * 60 * 60 || ratingResetAfterLastGame {
                return []
            }
        }
        return sessionGames
    }
    
    private func deleteOldGames(games: [BattlegroundsLastGames.GameItem]) {
        games.forEach({ x in
            if abs(x.startTime.timeIntervalSinceNow) > 7 * 24 * 60 * 60 {
                BattlegroundsLastGames.instance.removeGame(startTime: x.startTime)
            }
        })
    }
    
    private func formatRating(mmr: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let mmrText = numberFormatter.string(from: NSNumber(value: mmr)) ?? "0"
        return mmrText
    }
}
