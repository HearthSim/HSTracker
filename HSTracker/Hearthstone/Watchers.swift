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
    static let battlegroundsTeammateBoardStateWatcher = BattlegroundsTeammateBoardStateWatcher()
    static let bigCardWatcher = BigCardWatcher()
    static let choicesWatcher = ChoicesWatcher()
    static let deckPickerWatcher = DeckPickerWatcher()
    static let discoverStateWatcher = DiscoverStateWatcher()
    static let dungeonRunDeckWatcher = DungeonRunDeckWatcher()
    static let experienceWatcher = ExperienceWatcher()
    static let pvpDungeonRunWatcher = PVPDungeonRunWatcher()
    static let queueWatcher = QueueWatcher()
    static let sceneWatcher = SceneWatcher()
    static let specialShopChoicesStateWatcher = SpecialShopChoicesStateWatcher()
    
    static func initialize() {
        arenaWatcher.onCompleteDeck = onDeckCompleted
        baconWatcher.change = onBaconChange
        battlegroundsLeaderboardWatcher.change = { _, args in
            let game = AppDelegate.instance().coreManager.game
            game.windowManager.battlegroundsOverlay.view.setHoveredBattlegroundsEntityId(args.hoveredEntityId)

        }
        battlegroundsTeammateBoardStateWatcher.change = onBattlegroundsTeammateBoardStateChange
        bigCardWatcher.change = onBigCardChange
        choicesWatcher.change = { _, args in
            AppDelegate.instance().coreManager.game.setChoicesVisible(args.currentChoice?.isVisible ?? false)
        }
        specialShopChoicesStateWatcher.change = { _, args in
            AppDelegate.instance().coreManager.game.handleSpecialShop(args)
        }
        deckPickerWatcher.change = onDeckPickerChange
        discoverStateWatcher.change = onDiscoverStateChange
        dungeonRunDeckWatcher.dungeonRunMatchStarted = { newrun, set in
            CoreManager.dungeonRunMatchStarted(newRun: newrun, set: set, isPVPDR: false)
        }
        dungeonRunDeckWatcher.dungeonInfoChanged = { info in
            CoreManager.updateDungeonRunDeck(info: info, isPVPDR: false)
        }
        experienceWatcher.newExperienceHandler = { _, args in
            AppDelegate.instance().coreManager.game.experienceChangedAsync(experience: args.experience, experienceNeeded: args.experienceNeeded, level: args.level, levelChange: args.levelChange, animate: args.animate)
        }
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
        battlegroundsTeammateBoardStateWatcher.stop()
        bigCardWatcher.stop()
        choicesWatcher.stop()
        specialShopChoicesStateWatcher.stop()
        deckPickerWatcher.stop()
        discoverStateWatcher.stop()
        dungeonRunDeckWatcher.stop()
        experienceWatcher.stop()
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
        }
    }
    
    private static func onBattlegroundsTeammateBoardStateChange(_ sender: BattlegroundsTeammateBoardStateWatcher, _ args: BattlegroundsTeammateBoardStateArgs) {
        AppDelegate.instance().coreManager.game.windowManager.battlegroundsHeroPicking.viewModel.isViewingTeammate = args.isViewingTeammate
        // rest is not used
    }
    
    private static func onBigCardChange(_ sender: BigCardWatcher, _ args: BigCardArgs) {
        AppDelegate.instance().coreManager.game.onBigCardChange(args)
    }
    
    private static func onDeckPickerChange(_ sender: DeckPickerWatcher, _ args: DeckPickerEventArgs) {
        AppDelegate.instance().coreManager.game.setDeckPickerState(args.selectedFormatType, args.decksOnPage, args.isModalOpen)
    }
    
    private static func onDiscoverStateChange(_ sender: DiscoverStateWatcher, _ args: DiscoverStateArgs) {
        let game = AppDelegate.instance().coreManager.game
        game.setRelatedCardsTrigger(args)
        if game.isTraditionalHearthstoneMatch {
            game.windowManager.playerTracker.highlightPlayerDeckCards(highlightSourceCardId: args.cardId)
        }
    }
}
