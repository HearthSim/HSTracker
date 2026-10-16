//
//  MirrorHelper.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 23/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

/**
 * MirrorHelper takes care of all Mirror-related activities
 */
struct MirrorHelper {
    
    /** Internal represenation of the mirror object, do not access it directly - guarded by stateLock */
    private static var _mirror: HearthMirror?
    
    // Serializes the reads made through the mirror. Only held while a read runs,
    // never while the mirror is being initialized (see ensureMirror()).
    private static let accessQueue = DispatchQueue(label: "net.hearthsim.hstracker.mirrorQueue", attributes: [])
    
    // Runs initMirror(). Kept apart from accessQueue so a slow init never makes a
    // reader - in particular one on the main thread - wait for it.
    private static let initQueue = DispatchQueue(label: "net.hearthsim.hstracker.mirrorInitQueue", attributes: [])
    
    // Guards _mirror, initPending and generation. Only ever held for a few
    // instructions, so it is safe to take on the main thread.
    private static let stateLock = NSLock()
    private static var initPending = false
    // Bumped by destroy() so an init that was already running when the game
    // exited does not publish a mirror for the dead process.
    private static var generation = 0
    
    private static var mirror: HearthMirror? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return MirrorHelper._mirror
    }
    
    // The first mirror access attaches to the game: acquireTaskportRight() is a
    // synchronous authorization call that can wait on the system prompt,
    // HearthMirror(pid:blocking:) can block while the game is still launching,
    // and initMirror() retries with sleeps. When that ran on the main thread -
    // the mirror is lazily created by whichever getter touches it first, after
    // launch and again after every destroy() - it hung the UI for up to a
    // minute (HSTRACKER-MN, HSTRACKER-MB, HSTRACKER-1PX). The init now always
    // runs on initQueue: a main thread caller only schedules it and carries on
    // with no mirror (every getter already copes with nil, since the game may
    // not be running), background callers still wait for it as before.
    private static func ensureMirror() {
        stateLock.lock()
        let ready = MirrorHelper._mirror != nil
        let pending = initPending
        stateLock.unlock()
        if ready {
            return
        }
        if Thread.isMainThread {
            if !pending {
                scheduleInit()
            }
            return
        }
        initQueue.sync {
            initIfNeeded()
        }
    }
    
    private static func scheduleInit() {
        stateLock.lock()
        if initPending || MirrorHelper._mirror != nil {
            stateLock.unlock()
            return
        }
        initPending = true
        stateLock.unlock()
        initQueue.async {
            initIfNeeded()
            stateLock.lock()
            initPending = false
            stateLock.unlock()
        }
    }
    
    // Must only run on initQueue
    private static func initIfNeeded() {
        stateLock.lock()
        let ready = MirrorHelper._mirror != nil
        let startGeneration = generation
        stateLock.unlock()
        if ready {
            return
        }
        // disable until we can fix memory reading
        guard let hsApp = CoreManager.hearthstoneApp else {
            //logger.error("Failed to initialize HearthMirror: game is not running")
            return
        }
        logger.verbose("Initializing HearthMirror with pid \(hsApp.processIdentifier)")
        
        let newMirror = MirrorHelper.initMirror(pid: hsApp.processIdentifier, blocking: false)
        
        stateLock.lock()
        if generation == startGeneration && MirrorHelper._mirror == nil {
            MirrorHelper._mirror = newMirror
        } else if newMirror != nil {
            logger.verbose("Discarding HearthMirror initialized before the mirror was destroyed")
        }
        stateLock.unlock()
    }
    
    // Ensures the mirror is initialized (see ensureMirror()) before running a read
    // on accessQueue - outside of it, so a reader never holds accessQueue for the
    // length of an init.
    private static func withMirrorAccess(_ body: () -> Void) {
        ensureMirror()
        accessQueue.sync(execute: body)
    }
    
    private static func initMirror(pid: Int32, blocking: Bool) -> HearthMirror? {
        
        // get rights to attach
        if acquireTaskportRight() != 0 {
            logger.error("acquireTaskportRight() failed!")
        }
        
        let mirror = HearthMirror(pid: pid,
                                  blocking: true)
        
        // waiting for mirror to be up and running
        var attempts = 0
        while attempts < 3 {
            if let battleTag = mirror.getBattleTag(), let logDir = mirror.getLogSessionDir(), !logDir.isEmpty {
                logger.verbose("Getting BattleTag from HearthMirror : \(battleTag)")
                logger.verbose("Log directory: \(logDir)")
                return mirror
            } else {
                // mirror might be partially initialized, reset
                logger.error("Mirror is not working yet, trying again...")
                Thread.sleep(forTimeInterval: 0.5)
                attempts += 1
            }
        }
        
        return nil
    }
    
    /**
     * De-initializes the current mirror object, thus any further mirror calls will fail until the next initMirror
     */
    static func destroy() {
        logger.verbose("Deinitializing mirror")
        // accessQueue waits for an in-flight read to finish with the old mirror
        MirrorHelper.accessQueue.sync {
            stateLock.lock()
            MirrorHelper._mirror = nil
            generation += 1
            stateLock.unlock()
        }
    }
    
    static func isInitialized() -> Bool {
        return mirror != nil
    }
    
    // MARK: - Account information
    
    static func getBattleTag() -> String? {
        var result: String?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBattleTag()
        }
        return result
    }
    
    static func getAccountId() -> MirrorAccountId? {
        var result: MirrorAccountId?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getAccountId()
        }
        return result
    }
    
    // MARK: - get player decks
    
    static func getDecks() -> [MirrorDeck]? {
        var result: [MirrorDeck]?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getDecks()
        }
        return result
    }
    
    static func getTemplateDeckById(deckId: Int) -> MirrorTemplateDeck? {
        var result: MirrorTemplateDeck?
        MirrorHelper.withMirrorAccess {
            if let templateDeckId = mirror?.findDeckTemplateId(forDeckIdInternal: Int32(deckId)) {
                result = mirror?.getTemplateDeck(byDeckTemplateId: templateDeckId.int32Value)
            }
        }
        return result
    }
    
    static func getSelectedDeck() -> Int64? {
        var result: Int64?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getSelectedDeck() as? Int64? ?? nil
        }
        return result
    }
    
    static func getArenaInfo() -> MirrorArenaInfo? {
        var result: MirrorArenaInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getArenaDeck()
        }
        return result
    }
    
    static func getEditedDeck() -> MirrorDeck? {
        var result: MirrorDeck?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getEditedDeck()
        }
        return result
    }
    
    // MARK: - collection
    
    static func getCollection() -> MirrorCollection? {
        var result: MirrorCollection?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getCollection()
        }
        return result
    }
    
    // MARK: - game mode
    static func isSpectating() -> Bool? {
        var result: Bool?
        if !isInitialized() {
            return false
        }
        MirrorHelper.withMirrorAccess {
            result = mirror?.isSpectating()
        }
        return result
    }
    
    static func getGameType() -> Int? {
        var result: Int?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getGameType() as? Int? ?? nil
        }
        return result
    }
    
    static func getMatchInfo() -> MirrorMatchInfo? {
        var result: MirrorMatchInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMatchInfo()
        }
        return result
    }
    
    static func getMedalData() -> MirrorMedalData? {
        var result: MirrorMedalData?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMedalData()
        }
        return result
    }
    
    static func getBattlegroundsRatingInfo() -> MirrorBattlegroundRatingInfo? {
        var result: MirrorBattlegroundRatingInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBattlegroundsRatingInfo()
        }
        return result
    }
    
    static func getArenaRatingInfo() -> MirrorArenaRatingInfo? {
        var result: MirrorArenaRatingInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getArenaRatingInfo()
        }
        return result
    }
    
    static func getBattlegroundsRatingChange() -> MirrorRatingChange? {
        var result: MirrorRatingChange?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBattlegroundsRatingChange()
        }
        return result
    }
    
    static func getFormat() -> Int? {
        var result: Int?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getFormat() as? Int? ?? nil
        }
        return result
    }
    
    static func getGameServerInfo() -> MirrorGameServerInfo? {
        var result: MirrorGameServerInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getGameServerInfo()
        }
        return result
    }
    
    // MARK: - arena
    
    static func getArenaDraftChoices() -> MirrorDraftChoices? {
        var result: MirrorDraftChoices?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getArenaDraftChoices()
        }
        return result
    }

    /// Full draft-screen state behind the Arenasmith overlay.
    ///
    /// The two version arguments are the cheap-skip HDT uses: when the deck list's
    /// slot collection `_version` is unchanged the mirror leaves `deckListData` /
    /// `redraftDeckListData` nil instead of re-marshalling every card on each tick.
    /// `resetCache` drops the mirror's cached Mono handles - pass true whenever the
    /// objects those handles point at may have been replaced (client state change,
    /// underground toggle, watcher start).
    static func getArenaState(deckListVersion: Int?, redraftDeckListVersion: Int?, resetCache: Bool) -> MirrorArenaState? {
        var result: MirrorArenaState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getArenaState(deckListVersion.map { NSNumber(value: $0) },
                                           redraftDeckListVersion: redraftDeckListVersion.map { NSNumber(value: $0) },
                                           resetCache: resetCache)
        }
        return result
    }

    // MARK: - brawl
    
    static func getBrawlInfo() -> MirrorBrawlInfo? {
        var result: MirrorBrawlInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBrawlInfo()
        }
        return result
    }
    
    // MARK: - dungeon
    
    static func getDungeonRunInfo(key: Int) -> MirrorDungeonInfo? {
        var result: MirrorDungeonInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getDungeonInfo(Int32(key))
        }
        return result
    }
    
    static func getPVPDungeonInfo() -> MirrorDungeonInfo? {
        var result: MirrorDungeonInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getPVPDungeonInfo()
        }
        return result
    }
    
    static func getPVPDungeonSeedDeck() -> MirrorDeck? {
        var result: MirrorDeck?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getPVPDungeonSeedDeck()
        }
        return result
    }
    
    static func getDungeonDeck(id: Int) -> [Int]? {
        var result: [Int]?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getDungeonDeck(Int32(id))?.compactMap({ x in x.intValue })
        }
        return result
    }
    
    static func getAdventureConfig() -> AdventureConfig? {
        var result: AdventureConfig?
        MirrorHelper.withMirrorAccess {
            let temp = mirror?.getAdventureConfig()
            var res = AdventureConfig()
            if let config = temp {
                res.adventureId = AdventureDbId(rawValue: config.selectedAdventure.intValue) ?? .invalid
                res.adventureModeId = AdventureModeDbId(rawValue: config.selectedMode.intValue) ?? .invalid
                res.selectedMission = config.selectedMission.intValue
                res.selectedDeckId = config.selectedDeckId.intValue
                result = res
            }
        }
        return result
    }
    
    static func getScenarioDeckId(id: Int) -> Int? {
        var result: Int?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getScenarioDeckId(Int32(id))?.intValue
        }
        return result
    }
    
    static func getAvailableBattlegroundsRaces() -> [NSNumber]? {
        var result: [NSNumber]?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getAvailableBattlegroundsRaces()
        }
        return result
    }
    
    static func getUnavailableBattlegroundsRaces() -> [NSNumber]? {
        var result: [NSNumber]?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getUnavailableBattlegroundsRaces()
        }
        return result
    }
    
    static func getRewardTrackData() -> MirrorRewardTrackData? {
        var result: MirrorRewardTrackData?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getRewardTrackData(Int32(RewardTrackType.global.rawValue))
        }
        return result
    }
    
    static func getMercenariesRating() -> Int? {
        var result: Int?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMercenariesRating() as? Int? ?? nil
        }
        return result
    }
    
    static func getMercenariesRatingChange() -> MirrorRatingChange? {
        var result: MirrorRatingChange?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMercenariesRatingChange()
        }
        return result
    }
    
    static func getMercenariesMapInfo() -> MirrorMercenariesMapInfo? {
        var result: MirrorMercenariesMapInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMercenariesMapInfo()
        }
        return result
    }
    
    static func getMercenariesVisitorTasks() -> [MirrorMercenariesVisitorTask]? {
        var result: [MirrorMercenariesVisitorTask]?
        
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMercenariesVisitorTasks()
        }
        return result
    }
    
    static func getMercenariesTaskData() -> [MirrorMercenariesTaskData]? {
        var result: [MirrorMercenariesTaskData]?
        
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMercenariesTaskData()
        }
        return result
    }
    
    static func getMercenariesInCollection() -> [MirrorMercenaryData]? {
        var result: [MirrorMercenaryData]?
        
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMercenariesInCollection()
        }
        return result
    }
    
    static func getMercenariesCollection() -> [MirrorCollectionMercenary]? {
        var result: [MirrorCollectionMercenary]?
        
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMercenariesCollection()
        }
        return result
    }
    
    static func getFindGameState() -> FindGameState? {
        var result: FindGameState?
        MirrorHelper.withMirrorAccess {
            result = FindGameState(rawValue: mirror?.getFindGameState().intValue ?? 0)
        }
        return result
    }
    
    static func getCardChoices() -> MirrorCardChoices? {
        var result: MirrorCardChoices?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getCardChoices()
        }
        return result
    }
    
    static func isShopOpen() -> Bool {
        var result: Bool?
        MirrorHelper.withMirrorAccess {
            result = mirror?.isShopOpen()
        }
        return result ?? false
    }
    
    static func isJournalOpen() -> Bool {
        var result: Bool?
        MirrorHelper.withMirrorAccess {
            result = mirror?.isJournalOpen()
        }
        return result ?? false
    }
    
    static func isPopupShowing() -> Bool {
        var result: Bool?
        MirrorHelper.withMirrorAccess {
            result = mirror?.isPopupShowing()
        }
        return result ?? false
    }
    
    static func isFriendsListVisible() -> Bool {
        var result: Bool?
        MirrorHelper.withMirrorAccess {
            result = mirror?.isFriendsListVisible()
        }
        return result ?? false
    }
    
    // GameMenu.s_instance.m_isShown - the escape menu, which HDT reads through
    // Reflection.Client.IsGameMenuShown() for its own UiWatcher.
    static func isGameMenuVisible() -> Bool {
        var result: Bool?
        MirrorHelper.withMirrorAccess {
            result = mirror?.isGameMenuVisible()
        }
        return result ?? false
    }
    
    static func getLogSessionDir() -> String {
        var result: String?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getLogSessionDir()
        }
        return result ?? ""
    }
    
    static func getDeckPickerDecksOnPage() -> [MirrorCollectionDeckBoxVisual?] {
        var result = [MirrorCollectionDeckBoxVisual?]()
        MirrorHelper.withMirrorAccess {
            if let data = mirror?.getDeckPickerDecksOnPage() {
                for x in data {
                    if x is NSNull {
                        result.append(nil)
                    } else if let cbv = x as? MirrorCollectionDeckBoxVisual {
                        result.append(cbv)
                    }
                }
            }
        }
        return result
    }
    
    static func getDeckPickerState() -> MirrorDeckPickerState? {
        var result: MirrorDeckPickerState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getDeckPickerState()
        }
        return result
    }
    
    static func isBlurActive() -> Bool {
        var result = false
        MirrorHelper.withMirrorAccess {
            result = mirror?.isBlurActive() ?? false
        }
        return result
    }
    
    static func getSceneMgrState() -> MirrorSceneMgrState? {
        var result: MirrorSceneMgrState?
        
        MirrorHelper.withMirrorAccess {
            result = mirror?.getSceneMgrState()
        }
        return result
    }
    
    static func isMulliganWaitingForUserInput() -> Bool {
        var result = false
        MirrorHelper.withMirrorAccess {
            result = mirror?.isMulliganWaitingForUserInput() ?? false
        }
        return result
    }

    // Raw values from the game's ActorStateType enum (only the cases the
    // Mulligan G-V2 live-confidence recalculation cares about).
    private enum MulliganActorState: Int {
        case cardSelected = 5 // used in Mulligan as Keep
        case cardPlayableMouseOver = 7
    }

    static func getMulliganLiveState() -> MulliganLiveState? {
        var result: MirrorMulliganState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMulliganState()
        }
        guard let result else { return nil }

        let cards = result.mulliganCards.map { card in
            MulliganLiveCardState(
                zonePosition: card.zonePosition.intValue,
                cardId: card.cardId,
                kept: card.state.intValue == MulliganActorState.cardSelected.rawValue,
                mouseOverInPlay: card.state.intValue == MulliganActorState.cardPlayableMouseOver.rawValue
            )
        }
        return MulliganLiveState(waitingForUserInput: result.waitingForUserInput, cards: cards)
    }

    static func getSelectedBattlegroundsGameMode() -> SelectedBattlegroundsGameMode {
        var result = SelectedBattlegroundsGameMode.unknown
        MirrorHelper.withMirrorAccess {
            result = SelectedBattlegroundsGameMode(rawValue: mirror?.getSelectedBattlegroundsGameMode().intValue ?? 0) ?? .unknown
        }
        return result
    }
    
    static func getBattlegroundsLeaderboardHoveredEntityId() -> Int? {
        var result: Int?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBattlegroundsLeaderboardHoveredEntityId()?.intValue
        }
        return result
    }
    
    static func getBattlegroundsTeammateBoardState() -> MirrorBattlegroundsTeammateBoardState? {
        var result: MirrorBattlegroundsTeammateBoardState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBattlegroundsTeammateBoardState()
        }
        return result
    }
    
    // MulliganManager.s_instance - the tooltip Hearthstone draws beside a
    // moused-over card during the Battlegrounds hero picking phase. HDT reads it
    // through Reflection.Client.GetMulliganTooltipState().
    static func getMulliganTooltipState() -> MirrorMulliganTooltipState? {
        var result: MirrorMulliganTooltipState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getMulliganTooltipState()
        }
        return result
    }
    
    static func getBigCardState() -> MirrorBigCardState? {
        var result: MirrorBigCardState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBigCardState()
        }
        return result
    }
    
    static func getDiscoverState() -> MirrorDiscoverState? {
        var result: MirrorDiscoverState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getDiscoverState()
        }
        return result
    }
    
    static func getSpecialShopChoiceState() -> MirrorSpecialShopChoicesState? {
        var result: MirrorSpecialShopChoicesState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getSpecialShopChoices()
        }
        return result
    }
    
    // HDT's Reflection.Client.GetBoardState(needsFriendlyZone). The friendly
    // zone is only ever needed for its board-entry-order overlay, which
    // HSTracker does not have, so every caller here passes false.
    static func getBoardState(includeFriendly: Bool) -> MirrorBoardState? {
        var result: MirrorBoardState?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBoardState(includeFriendly)
        }
        return result
    }

    static func getBattlegroundsLobbyInfo() -> MirrorBattlegroundsLobbyInfo? {
        var result: MirrorBattlegroundsLobbyInfo?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBattlegroundsLobbyInfo()
        }
        return result
    }

    static func getBattlegroundsMinionPool() -> MirrorBattlegroundsMinionPool? {
        var result: MirrorBattlegroundsMinionPool?
        MirrorHelper.withMirrorAccess {
            result = mirror?.getBattlegroundsMinionPool()
        }
        return result
    }
}

