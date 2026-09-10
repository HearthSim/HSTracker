//
//  BattlegroundsSessionViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Port of HDT's BattlegroundsSessionViewModel
// (Controls/Overlay/Battlegrounds/Session/BattlegroundsSessionViewModel.xaml.cs).
// Every Visibility property there becomes a Bool here; the sections they gate
// are laid out by BattlegroundsSessionView.
//
// The one deliberate divergence from HDT is the MMR section: HSTracker lets the
// user pick between HDT's fixed "Start | Current" pair and a "Current | Change"
// pair that shows the session delta, coloured green/red (Settings.showMMRStartCurrent).
// That is why the two columns are exposed as generic A/B label+value pairs
// rather than HDT's BgRatingStart/BgRatingCurrent.
@available(macOS 10.15, *)
class BattlegroundsSessionViewModel: ObservableObject {
    // MARK: - Minion types

    @Published var availableMinionTypes = [Race]()
    @Published var bannedMinionTypes = [Race]()

    @Published var availableMinionTypesSectionVisible = false
    @Published var bannedMinionTypesSectionVisible = false
    @Published var minionTypesBodyVisible = false
    @Published var minionTypesWaitingMsgVisible = false

    // HDT's MinionTypesSectionVisibility.
    var minionTypesSectionVisible: Bool {
        availableMinionTypesSectionVisible || bannedMinionTypesSectionVisible
    }

    // HDT's MinionTypesBorderVisibility - the separator between the two lists
    // only exists when both are on.
    var minionTypesBorderVisible: Bool {
        availableMinionTypesSectionVisible && bannedMinionTypesSectionVisible
    }

    // HDT's AvailableMinionTypesHeaderLabel.
    var minionTypesHeaderLabel: String {
        switch (availableMinionTypesSectionVisible, bannedMinionTypesSectionVisible) {
        case (true, false):
            return String.localizedString("Battlegrounds_Session_Header_Label_Minions_Available", comment: "")
        case (false, true):
            return String.localizedString("Battlegrounds_Session_Header_Label_Minions_Banned", comment: "")
        default:
            return String.localizedString("Battlegrounds_Session_Header_Label_Minions_MinionTypes", comment: "")
        }
    }

    // MARK: - MMR

    @Published var mmrSectionVisible = false
    @Published var mmrLabelA = ""
    @Published var mmrValueA = "0"
    @Published var mmrLabelB = ""
    @Published var mmrValueB = "0"
    @Published var mmrValueBColor = Color.white

    // MARK: - Latest games

    @Published var latestGamesSectionVisible = false
    @Published var sessionGames = [BattlegroundsGameRowViewModel]()
    @Published var gridHeaderVisible = false
    @Published var gamesEmptyStateVisible = false

    // MARK: - Composition stats

    @Published var availableCompStatsSectionVisible = false
    @Published var compStatsBodyVisible = false
    @Published var compStatsWaitingMsgVisible = false
    @Published var compStatsErrorVisible = false
    @Published var compositionStats: [BattlegroundsCompositionStatsRowViewModel]?

    // MARK: - Chrome

    // HDT's CogBtnVisibility: the settings button only appears while the cursor
    // is over the panel (Panel_MouseEnter/Panel_MouseLeave).
    @Published var isCogVisible = false

    // Settings.battlegroundsSessionScaling, applied to the whole panel by
    // BattlegroundsSessionRootView.
    @Published var scaling: Double = Settings.battlegroundsSessionScaling

    // The panel's laid-out (unscaled) size, reported back by the view.
    @Published var panelSize: CGSize = .zero

    // Where the panel ends up inside its window once scaled - the pixels the
    // window has to stop being click-through over. Its origin is (0, 0)
    // because BattlegroundsSessionRootView pins the panel to the window's
    // top-left corner.
    var panelRegion: CGRect {
        CGRect(x: 0, y: 0,
               width: panelSize.width * CGFloat(scaling),
               height: panelSize.height * CGFloat(scaling))
    }

    // Which side of the Hearthstone window the panel sits on, which decides
    // whether a game row's final-board tooltip opens to its right or its left
    // (HDT's `tooltipToRight` in BattlegroundsGameViewModel.OnMouseEnter).
    @Published var tooltipToRight = true

    // MARK: - Mode

    private let updateCompStatsSemaphore = UnfairLock()

    private var _battlegroundsGameMode: SelectedBattlegroundsGameMode = .unknown

    var battlegroundsGameMode: SelectedBattlegroundsGameMode {
        get {
            return _battlegroundsGameMode
        }
        set {
            // the client reports UNKNOWN whenever the lobby is not showing (during a game, in another
            // scene) and the watcher coerces failed mirror reads to it too, so it never tells us which
            // mode the player is in. Keeping the last mode we actually saw avoids falling back to Solos.
            if newValue == .unknown { return }
            let modified = _battlegroundsGameMode != newValue
            _battlegroundsGameMode = newValue
            if modified {
                DispatchQueue.main.async {
                    self.updateSectionsVisibilities()
                    Task.detached {
                        await self.updateCompositionStatsVisibility()
                    }
                    self.update()
                }
            }
        }
    }

    private var isDuos: Bool {
        let game = AppDelegate.instance().coreManager.game
        return game.isInMenu ? battlegroundsGameMode == .duos : game.isBattlegroundsDuosMatch()
    }

    // MARK: - Updates

    @MainActor
    func updateSectionsVisibilities() {
        availableMinionTypesSectionVisible = Settings.showMinionsSection && Settings.showMinionsAvailable
        bannedMinionTypesSectionVisible = Settings.showMinionsSection && Settings.showMinionsBanned
        mmrSectionVisible = Settings.showMMR
        latestGamesSectionVisible = Settings.showLatestGames
    }

    func onGameStart() {
        if AppDelegate.instance().coreManager.game.spectator {
            return
        }
        update()
    }

    func onGameEnd() {
        if AppDelegate.instance().coreManager.game.spectator {
            return
        }
        update()
    }

    func update() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.update()
            }
            return
        }

        updateMinionTypes()

        // Update method might be called multiple times.
        // We need to prevent multiple calls to UpdateCompositionStatsIfNeeded to happen at the same time.
        // This also ensures only one API call is made.
        updateCompStatsSemaphore.lock()
        defer {
            updateCompStatsSemaphore.unlock()
        }
        Task.init {
            await updateCompositionStatsIfNeeded()
        }

        let firstGame = updateLatestGames()

        let game = AppDelegate.instance().coreManager.game
        let rating = BattlegroundsSessionViewModel.clientRating(ratingInfo: game.battlegroundsRatingInfo, duos: isDuos) ?? 0
        let ratingStart = firstGame?.rating ?? rating

        if Settings.showMMRStartCurrent {
            mmrLabelA = String.localizedString("Battlegrounds_Session_MMR_Label_Start", comment: "")
            mmrValueA = formatRating(mmr: ratingStart)
            mmrLabelB = String.localizedString("Battlegrounds_Session_MMR_Label_Current", comment: "")
            mmrValueB = formatRating(mmr: rating)
            mmrValueBColor = .white
        } else {
            mmrLabelA = String.localizedString("Battlegrounds_Session_MMR_Label_Current", comment: "")
            mmrValueA = formatRating(mmr: rating)
            mmrLabelB = String.localizedString("Change", comment: "")
            let mmrDelta = rating - ratingStart
            mmrValueB = "\(mmrDelta > 0 ? "+" : "")\(formatRating(mmr: mmrDelta))"
            mmrValueBColor = mmrDelta == 0 ? .white : mmrDelta > 0 ? BattlegroundsSessionColors.mmrPositive : BattlegroundsSessionColors.mmrNegative
        }
    }

    // HDT's UpdateMinionTypes.
    private func updateMinionTypes() {
        let game = AppDelegate.instance().coreManager.game
        let allRaces = Database.battlegroundRaces.filter { $0 != .invalid && $0 != .all }
        let availableRaces = game.availableRaces ?? allRaces
        let unavailableRaces = allRaces.filter { !availableRaces.contains($0) }

        let validMinionTypes = unavailableRaces.count >= 5 && unavailableRaces.count != allRaces.count
        if validMinionTypes {
            availableMinionTypes = availableRaces.sorted { BattlegroundsMinionType.raceName($0) < BattlegroundsMinionType.raceName($1) }
            bannedMinionTypes = unavailableRaces.sorted { BattlegroundsMinionType.raceName($0) < BattlegroundsMinionType.raceName($1) }
        }

        if (game.currentMode == .gameplay || SceneHandler.scene == .gameplay) && validMinionTypes {
            minionTypesBodyVisible = true
            minionTypesWaitingMsgVisible = false
        } else {
            minionTypesBodyVisible = false
            minionTypesWaitingMsgVisible = true
        }
    }

    // MARK: - Composition stats

    func updateCompositionStatsVisibility() async {
        let userOwnsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false

        if let acc = MirrorHelper.getAccountId() {
            if !userOwnsTier7 {
                await Tier7Trial.update(hi: acc.hi.int64Value, lo: acc.lo.int64Value)
            }
        }
        let visible: Bool
        if isDuos || !Settings.showBattlegroundsTier7SessionCompStats {
            visible = false
        } else {
            visible = userOwnsTier7 || Tier7Trial.remainingTrials ?? 0 > 0 || compositionStats != nil
        }
        await MainActor.run {
            availableCompStatsSectionVisible = visible
        }
    }

    @MainActor
    private func setBattlegroundsCompositionStatsViewModel(_ compData: [BattlegroundsCompStats.LobbyComp]) {
        let compStatsOrdered = compData.sorted(by: { (a, b) -> Bool in a.popularity > b.popularity })

        if compStatsOrdered.count > 0 {
            let max = max(ceil(compStatsOrdered[0].popularity), 40.0)

            compositionStats = compStatsOrdered.filter { comp in comp.id != -1 && comp.name != nil }.compactMap { comp in
                let minionDbfId = comp.key_minions_top3 == nil || comp.key_minions_top3?.count == 0 ? 59201 : comp.key_minions_top3?[0] ?? 59201
                return BattlegroundsCompositionStatsRowViewModel(comp.name ?? "", minionDbfId, comp.popularity, comp.avg_final_placement, max)
            }
        }
    }

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

    @MainActor
    private func clearCompositionStats() {
        compositionStats = nil
        compStatsBodyVisible = false
        compStatsWaitingMsgVisible = true
        compStatsErrorVisible = false
    }

    @MainActor
    private func showCompositionStats() {
        compStatsBodyVisible = true
        compStatsWaitingMsgVisible = false
        compStatsErrorVisible = false

        AppDelegate.instance().coreManager.game.updateBattlegroundsOverlays()
    }

    private func updateCompositionStatsIfNeeded() async {
        let game = AppDelegate.instance().coreManager.game

        if game.currentMode != .gameplay || SceneHandler.scene != .gameplay {
            await clearCompositionStats()
            return
        }

        // Ensures data was already fetched and no more API calls are needed
        if ((compositionStats != nil && compositionStats?.count != 0) || compStatsErrorVisible) && (game.currentMode == .gameplay || SceneHandler.scene == .gameplay) {
            return
        }

        await trySetCompStats()
    }

    private func trySetCompStats() async {
        do {
            if let compStats = try await getBattlegroundsCompStats() {
                await setBattlegroundsCompositionStatsViewModel(compStats.data.first_place_comps_lobby_races)
                await showCompositionStats()
            }
        } catch {
            await handleCompStatsError(error)
        }
    }

    @MainActor
    func hideCompStatsOnError() {
        if compStatsErrorVisible {
            availableCompStatsSectionVisible = false
        }
    }

    @MainActor
    private func handleCompStatsError(_ error: Error) {
        logger.error(error)

        let game = AppDelegate.instance().coreManager.game

        let beforeHeroPicked = (game.gameEntity?[GameTag.step] ?? 0) <= Step.begin_mulligan.rawValue
        if !beforeHeroPicked {
            Task.detached {
                // Ensure update after 20 seconds
                await Task.sleep(milliseconds: 20_000)
                await self.hideCompStatsOnError()
            }
        }

        compStatsErrorVisible = true
        compStatsBodyVisible = false
        compStatsWaitingMsgVisible = false
    }

    // MARK: - Latest games

    private func updateLatestGames() -> BattlegroundsLastGames.GameItem? {
        let duos = isDuos
        let ratingInfo = AppDelegate.instance().coreManager.game.battlegroundsRatingInfo
        let sortedGames = BattlegroundsLastGames.instance.getPlayerGames(duos: duos).sorted(by: { (a, b) in a.startTime < b.startTime })
        deleteOldGames(games: sortedGames)
        var games = getSessionGames(sortedGames: sortedGames, ratingInfo: ratingInfo, duos: duos)
        let firstGame = games.first
        if games.count > 8 {
            games.removeSubrange(0 ..< games.count - 8)
        }
        sessionGames = games
            .sorted(by: { (a, b) in a.startTime > b.startTime })
            .map { BattlegroundsGameRowViewModel(gameItem: $0) }

        gridHeaderVisible = !sessionGames.isEmpty
        gamesEmptyStateVisible = sessionGames.isEmpty

        return firstGame
    }

    private static func clientRating(ratingInfo: MirrorBattlegroundRatingInfo?, duos: Bool) -> Int? {
        // Duos and Solos are separate ladders, so mixing them up makes a Duos rating look like a season reset
        return duos ? ratingInfo?.duosRating.intValue : ratingInfo?.rating.intValue
    }

    private func getSessionGames(sortedGames: [BattlegroundsLastGames.GameItem], ratingInfo: MirrorBattlegroundRatingInfo?, duos: Bool) -> [BattlegroundsLastGames.GameItem] {
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
            if let currentMMR = BattlegroundsSessionViewModel.clientRating(ratingInfo: ratingInfo, duos: duos) {
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
        numberFormatter.locale = Language.culture
        let mmrText = numberFormatter.string(from: NSNumber(value: mmr)) ?? "0"
        return mmrText
    }
}

// The literal brushes HDT hands out from BattlegroundsGameViewModel's
// PlacementTextBrush/MMRDeltaTextBrush, kept in one place because the session's
// MMR "Change" column colours itself with the same two.
@available(macOS 10.15, *)
enum BattlegroundsSessionColors {
    static let placementLow = Color(red: 109.0 / 255.0, green: 235.0 / 255.0, blue: 108.0 / 255.0)
    static let placementHigh = Color(red: 236.0 / 255.0, green: 105.0 / 255.0, blue: 105.0 / 255.0)
    static let mmrPositive = Color(red: 139.0 / 255.0, green: 210.0 / 255.0, blue: 134.0 / 255.0)
    static let mmrNegative = Color(red: 236.0 / 255.0, green: 105.0 / 255.0, blue: 105.0 / 255.0)
}
