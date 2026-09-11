//
//  Watchers.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Watchers {
    static let arenaWatcher = ArenaWatcher()
    static let baconWatcher = BaconWatcher()
    static let battlegroundsLeaderboardWatcher = BattlegroundsLeaderboardWatcher()
    static let battlegroundsLobbyInfoWatcher = BattlegroundsLobbyInfoWatcher()
    static let battlegroundsTeammateBoardStateWatcher = BattlegroundsTeammateBoardStateWatcher()
    static let bigCardWatcher = BigCardWatcher()
    static let choicesWatcher = ChoicesWatcher()
    static let deckPickerWatcher = DeckPickerWatcher()
    static let discoverStateWatcher = DiscoverStateWatcher()
    static let mulliganTooltipWatcher = MulliganTooltipWatcher()
    static let dungeonRunDeckWatcher = DungeonRunDeckWatcher()
    static let experienceWatcher = ExperienceWatcher()
    static let playZoneWatcher = PlayZoneWatcher()
    static let pvpDungeonRunWatcher = PVPDungeonRunWatcher()
    static let queueWatcher = QueueWatcher()
    static let sceneWatcher = SceneWatcher()
    static let specialShopChoicesStateWatcher = SpecialShopChoicesStateWatcher()
    
    static func initialize() {
        arenaWatcher.onCompleteDeck = onDeckCompleted
        baconWatcher.change = onBaconChange
        battlegroundsLeaderboardWatcher.change = { _, args in
            if #available(macOS 10.15, *) {
                let game = AppDelegate.instance().coreManager.game
                game.windowManager.rootOverlay?.viewModel.battlegroundsOpponentInfo
                    .setHoveredEntityId(args.hoveredEntityId)
            }
        }
        battlegroundsLobbyInfoWatcher.change = onBattlegroundsLobbyInfoChange
        battlegroundsTeammateBoardStateWatcher.change = onBattlegroundsTeammateBoardStateChange
        bigCardWatcher.change = onBigCardChange
        choicesWatcher.change = { _, args in
            AppDelegate.instance().coreManager.game.setChoicesVisible(args.currentChoice?.isVisible ?? false,
                                                                      args.currentChoice?.cards)
        }
        specialShopChoicesStateWatcher.change = { _, args in
            AppDelegate.instance().coreManager.game.handleSpecialShop(args)
        }
        deckPickerWatcher.change = onDeckPickerChange
        discoverStateWatcher.change = onDiscoverStateChange
        mulliganTooltipWatcher.change = onMulliganTooltipChange
        dungeonRunDeckWatcher.dungeonRunMatchStarted = { newrun, set in
            CoreManager.dungeonRunMatchStarted(newRun: newrun, set: set, isPVPDR: false)
        }
        dungeonRunDeckWatcher.dungeonInfoChanged = { info in
            CoreManager.updateDungeonRunDeck(info: info, isPVPDR: false)
        }
        experienceWatcher.newExperienceHandler = { _, args in
            AppDelegate.instance().coreManager.game.experienceChangedAsync(experience: args.experience, experienceNeeded: args.experienceNeeded, level: args.level, levelChange: args.levelChange, animate: args.animate)
        }
        playZoneWatcher.change = onPlayZoneChange
        pvpDungeonRunWatcher.pvpDungeonRunMatchStarted = { newrun, set in
            CoreManager.dungeonRunMatchStarted(newRun: newrun, set: set, isPVPDR: true)
        }
        pvpDungeonRunWatcher.pvpDungeonInfoChanged = { info in
            CoreManager.updateDungeonRunDeck(info: info, isPVPDR: true)
        }
        queueWatcher.inQueueChanged = { _, args in
            AppDelegate.instance().coreManager.game.queueEvents.handle(args)
        }
        sceneWatcher.change = { _, args in
            SceneHandler.onSceneUpdate(prevMode: Mode.allCases[args.prevMode], mode: Mode.allCases[args.mode], sceneLoaded: args.sceneLoaded, transitioning: args.transitioning)
        }
    }
    
    static func stop() {
        arenaWatcher.stop()
        baconWatcher.stop()
        battlegroundsLeaderboardWatcher.stop()
        battlegroundsLobbyInfoWatcher.stop()
        battlegroundsTeammateBoardStateWatcher.stop()
        bigCardWatcher.stop()
        choicesWatcher.stop()
        specialShopChoicesStateWatcher.stop()
        deckPickerWatcher.stop()
        discoverStateWatcher.stop()
        mulliganTooltipWatcher.stop()
        dungeonRunDeckWatcher.stop()
        experienceWatcher.stop()
        playZoneWatcher.stop()
        pvpDungeonRunWatcher.stop()
        queueWatcher.stop()
        sceneWatcher.stop()
    }
    
    private static func onDeckCompleted(_ sender: ArenaWatcher, _ args: CompleteDeckEventArgs) {
        if let deck = RealmHelper.autoImportArena(args.info) {
            AppDelegate.instance().coreManager.game.set(activeDeck: deck, autoDetected: true)
        }
        // TODO: _currentArenaDraftInfo.remove(args.info.deck.id)
    }
    
    private static func onBaconChange(_ sender: BaconWatcher, _ args: BaconEventArgs) {
        if #available(macOS 10.15, *) {
            let game = AppDelegate.instance().coreManager.game
            game.setBaconState(args.selectedBattlegroundsGameMode, args.isAnyOpen())
            game.updateBattlegroundsSessionVisibility(args.isFriendsListOpen)
            // HDT does this from Watchers.OnUiChange, whose UIWatcher this
            // BaconWatcher stands in for here.
            game.setFriendListOpacityMask(args.isFriendsListOpen)
            game.setGameMenuOpacityMask(args.isGameMenuShown)
        }
    }
    
    private static func onBattlegroundsTeammateBoardStateChange(_ sender: BattlegroundsTeammateBoardStateWatcher, _ args: BattlegroundsTeammateBoardStateArgs) {
        if #available(macOS 10.15, *) {
            AppDelegate.instance().coreManager.game.windowManager.rootOverlay?.viewModel.battlegroundsHeroPicking.isViewingTeammate = args.isViewingTeammate
        }
        // rest is not used
    }
    
    // Mirrors HDT's Watchers.OnPlayZoneChange. In Battlegrounds the opposing
    // play zone is Bob's shop; outside of it nothing consumes the board state
    // here, so the fallback list isn't built on every tick.
    private static func onPlayZoneChange(_ sender: PlayZoneWatcher, _ args: BoardStateArgs) {
        let game = AppDelegate.instance().coreManager.game
        guard game.isBattlegroundsMatch() else { return }
        game.handleShopBoardState(boardCards: args.opposing?.boardCards ?? [],
                                  mousedOverSlot: args.opposing?.mousedOverSlot ?? -1)
    }

    private static func onBigCardChange(_ sender: BigCardWatcher, _ args: BigCardArgs) {
        AppDelegate.instance().coreManager.game.onBigCardChange(args)
    }
    
    // HDT's Watchers.OnMulliganTooltipChange: the mask cut away over the game's
    // hero picking tooltip, and the hover trigger that raises the hovered
    // hero's guide over it.
    private static func onMulliganTooltipChange(_ sender: MulliganTooltipWatcher, _ args: MulliganTooltipArgs) {
        let game = AppDelegate.instance().coreManager.game
        let buddiesEnabled = (game.gameEntity?[.bacon_buddy_enabled] ?? 0) > 0
        game.setHeroPickingTooltipMask(zoneSize: args.zoneSize,
                                       zonePosition: args.zonePosition,
                                       tooltipOnRight: args.isTooltipOnRight,
                                       numCards: args.tooltipCards.count,
                                       buddiesEnabled: buddiesEnabled)
        game.setHeroGuidesTrigger(zoneSize: args.zoneSize,
                                  zonePosition: args.zonePosition,
                                  tooltipOnRight: args.isTooltipOnRight,
                                  cards: args.tooltipCards,
                                  buddiesEnabled: buddiesEnabled)
    }
    
    private static func onDeckPickerChange(_ sender: DeckPickerWatcher, _ args: DeckPickerEventArgs) {
        AppDelegate.instance().coreManager.game.setDeckPickerState(args.selectedFormatType, args.decksOnPage, args.isModalOpen)
    }
    
    private static func onDiscoverStateChange(_ sender: DiscoverStateWatcher, _ args: DiscoverStateArgs) {
        let game = AppDelegate.instance().coreManager.game
        game.setRelatedCardsTrigger(args)
        game.setQuestGuidesTrigger(args)
        // This runs on the DiscoverStateWatcher queue. highlightPlayerDeckCards
        // reaches into the tracker window and marks card bars for redisplay, so
        // it has to run on the main thread - Game.onBigCardChange hops for the
        // same call (Sentry HSTRACKER-304).
        DispatchQueue.main.async {
            if game.isTraditionalHearthstoneMatch {
                game.windowManager.playerTracker.highlightPlayerDeckCards(highlightSourceCardId: args.cardId)
            }
        }
    }
    
    private static func onBattlegroundsLobbyInfoChange(_ sender: BattlegroundsLobbyInfoWatcher, _ args: BattlegroundsLobbyInfoArgs) {
        AppDelegate.instance().coreManager.game.battlegroundsLobbyInfo = args.lobbyInfo
    }
}
