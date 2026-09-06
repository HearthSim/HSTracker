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
    static let arenaStateWatcher = ArenaStateWatcher()
    static let baconWatcher = BaconWatcher()
    static let battlegroundsLeaderboardWatcher = BattlegroundsLeaderboardWatcher()
    static let battlegroundsLobbyInfoWatcher = BattlegroundsLobbyInfoWatcher()
    static let battlegroundsTeammateBoardStateWatcher = BattlegroundsTeammateBoardStateWatcher()
    static let bigCardWatcher = BigCardWatcher()
    static let choicesWatcher = ChoicesWatcher()
    static let deckPickerWatcher = DeckPickerWatcher()
    static let discoverStateWatcher = DiscoverStateWatcher()
    static let dungeonRunDeckWatcher = DungeonRunDeckWatcher()
    static let experienceWatcher = ExperienceWatcher()
    static let playZoneWatcher = PlayZoneWatcher()
    static let pvpDungeonRunWatcher = PVPDungeonRunWatcher()
    static let queueWatcher = QueueWatcher()
    static let sceneWatcher = SceneWatcher()
    static let specialShopChoicesStateWatcher = SpecialShopChoicesStateWatcher()
    
    static func initialize() {
        arenaWatcher.onCompleteDeck = onDeckCompleted
        arenaWatcher.onChoicesChanged = onArenaChoicesChanged
        arenaWatcher.onCardPicked = onArenaCardPicked
        arenaWatcher.onRedraftChoicesChanged = onArenaRedraftChoicesChanged
        arenaWatcher.onRedraftCardPicked = onArenaRedraftCardPicked
        baconWatcher.change = onBaconChange
        battlegroundsLeaderboardWatcher.change = { _, args in
            let game = AppDelegate.instance().coreManager.game
            game.windowManager.battlegroundsOverlay.view.setHoveredBattlegroundsEntityId(args.hoveredEntityId)

        }
        battlegroundsLobbyInfoWatcher.change = onBattlegroundsLobbyInfoChange
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
        arenaStateWatcher.stop()
        baconWatcher.stop()
        battlegroundsLeaderboardWatcher.stop()
        battlegroundsLobbyInfoWatcher.stop()
        battlegroundsTeammateBoardStateWatcher.stop()
        bigCardWatcher.stop()
        choicesWatcher.stop()
        specialShopChoicesStateWatcher.stop()
        deckPickerWatcher.stop()
        discoverStateWatcher.stop()
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
        currentArenaDraftInfo.removeValue(forKey: args.info.deck.id.int64Value)
    }

    // Choices offered at each slot, plus when they went up, so a pick can be
    // recorded with the choices it was made from and how long it took.
    private struct ArenaSlotInfo {
        let choices: [String]
        let packages: [[String]]?
        let pickStartTime: Date
    }
    private static var currentArenaDraftInfo = [Int64: [Int: ArenaSlotInfo]]()

    private static func onArenaChoicesChanged(_ sender: ArenaWatcher, _ args: ChoicesChangedEventArgs) {
        let deckId = args.deck.id.int64Value
        let info = ArenaSlotInfo(choices: args.choices.map { $0.cardId },
                                 packages: args.packages?.map { $0.map { c in c.cardId } },
                                 pickStartTime: Date())
        currentArenaDraftInfo[deckId, default: [:]][args.slot] = info
    }

    private static func onArenaRedraftChoicesChanged(_ sender: ArenaWatcher, _ args: RedraftChoicesChangedEventArgs) {
        let deckId = args.redraftDeck.id.int64Value
        let info = ArenaSlotInfo(choices: args.choices.map { $0.cardId },
                                 packages: nil,
                                 pickStartTime: Date())
        currentArenaDraftInfo[deckId, default: [:]][args.slot] = info
    }

    /// A package pick consumes several slots at once, so when the exact slot has no
    /// recorded choices HDT falls back to `slot - packageSize`.
    private static func arenaSlotInfo(deckId: Int64, slot: Int, packageSize: Int) -> ArenaSlotInfo? {
        guard let draftInfo = currentArenaDraftInfo[deckId] else { return nil }
        if let info = draftInfo[slot], !info.choices.isEmpty {
            return info
        }
        if packageSize > 0, let info = draftInfo[slot - packageSize], !info.choices.isEmpty {
            return info
        }
        return nil
    }

    private static func structurePackages(_ choices: [String], _ packages: [[String]]?) -> [String: [String]]? {
        guard let packages, !packages.isEmpty else { return nil }
        var result = [String: [String]]()
        for (index, choice) in choices.enumerated() {
            if index >= packages.count { break }
            result[choice] = packages[index]
        }
        return result
    }

    private static func onArenaCardPicked(_ sender: ArenaWatcher, _ args: CardPickedEventArgs) {
        let deckId = args.deck.id.int64Value
        let packageSize = args.pickedPackage?.count ?? 0
        guard let info = arenaSlotInfo(deckId: deckId, slot: args.slot, packageSize: packageSize) else {
            return
        }

        // The deck already contains the card just picked, so drop one copy of it to
        // get the deck as it was when the choice was offered.
        let pickedCards = args.deck.cards.flatMap { card -> [String] in
            let count = card.cardId == args.picked.cardId
                ? max(0, card.count.intValue - 1)
                : card.count.intValue
            return Array(repeating: card.cardId, count: count)
        }

        ArenaLastDrafts.instance.addPick(info.pickStartTime,
                                         Date(),
                                         args.picked.cardId,
                                         info.choices,
                                         args.slot,
                                         false,
                                         pickedCards,
                                         deckId,
                                         args.isUnderground,
                                         args.pickedPackage?.map { $0.cardId },
                                         structurePackages(info.choices, info.packages),
                                         isOverlayEnabled: Settings.enableArenasmithOverlay && Settings.showArenasmithScore)

        // A dual-class draft spends an extra slot on the hero power, so its last
        // card lands on slot 31 rather than 30. Once it is picked there is nothing
        // left to advise on, and the overlay comes down.
        let heroPower = args.deck.heroPower
        let isDualClass = !heroPower.isEmpty
            && Cards.any(byId: heroPower)?.playerClass != Cards.any(byId: args.deck.hero)?.playerClass
        if args.slot == (isDualClass ? 31 : 30) {
            DispatchQueue.main.async {
                if #available(macOS 10.15, *) {
                    AppDelegate.instance().coreManager.game.windowManager
                        .rootOverlay?.viewModel.arenaPickHelper.reset()
                }
            }
        }
    }

    private static func onArenaRedraftCardPicked(_ sender: ArenaWatcher, _ args: RedraftCardPickedEventArgs) {
        let redraftDeckId = args.redraftDeck.id.int64Value
        guard let info = arenaSlotInfo(deckId: redraftDeckId, slot: args.slot, packageSize: 0) else {
            return
        }

        let originalDeck = args.deck.cards.flatMap { card in
            Array(repeating: card.cardId, count: card.count.intValue)
        }
        let redraftDeck = args.redraftDeck.cards.flatMap { card -> [String] in
            let count = card.cardId == args.picked.cardId
                ? max(0, card.count.intValue - 1)
                : card.count.intValue
            return Array(repeating: card.cardId, count: count)
        }

        ArenaLastDrafts.instance.addRedraftPick(info.pickStartTime,
                                                Date(),
                                                args.picked.cardId,
                                                info.choices,
                                                args.slot,
                                                false,
                                                originalDeck,
                                                redraftDeck,
                                                args.deck.id.int64Value,
                                                redraftDeckId,
                                                args.losses,
                                                args.isUnderground,
                                                isOverlayEnabled: Settings.enableArenasmithOverlay && Settings.showArenasmithScore)
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
    
    private static func onDeckPickerChange(_ sender: DeckPickerWatcher, _ args: DeckPickerEventArgs) {
        AppDelegate.instance().coreManager.game.setDeckPickerState(args.selectedFormatType, args.decksOnPage, args.isModalOpen)
    }
    
    private static func onDiscoverStateChange(_ sender: DiscoverStateWatcher, _ args: DiscoverStateArgs) {
        let game = AppDelegate.instance().coreManager.game
        game.setRelatedCardsTrigger(args)
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
