//
//  BattlegroundsOpponentInfoViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Drives the two things HDT's OverlayWindow puts up while the cursor is over a
// hero on the Battlegrounds leaderboard:
//
//  - BgsOpponentInfo, the hovered opponent's last known warband plus their
//    tavern-up turns and triples (BattlegroundsOpponentInfo.xaml), and
//  - the eight BattlegroundsTileText/BattlegroundsTurnText pairs that label each
//    leaderboard slot with how long that player has been dead
//    (OverlayWindow.xaml, positioned by OverlayWindow.MouseOverDetection.cs).
//
// They share this one view model because they share their trigger: HDT drives
// both from _leaderboardHoveredEntityId in a single UpdateBattlegroundsOverlay
// pass, which is what update() below is the port of.
@available(macOS 10.15, *)
final class BattlegroundsOpponentInfoViewModel: ObservableObject {
    // One leaderboard slot's triples/tavern-up state, which is what a
    // BattlegroundsTierTriples control renders.
    struct TierTriples: Equatable {
        let tier: Int
        let qty: Int
        let turn: Int
    }

    // One of the two quest badges. Quests are HSTracker's own addition to this
    // panel - HDT's BattlegroundsOpponentInfo has never shown them - so they are
    // carried over from the AppKit panel rather than ported from any XAML.
    struct Quest: Equatable {
        let dbfId: Int
        let turn: Int
    }

    // BgsOpponentInfo.Visibility.
    @Published var isShown = false
    // The _leaderboardDeadForText / _leaderboardDeadForTurnText visibility,
    // which HDT ties to *any* hovered leaderboard hero - including your own and,
    // in Duos, your teammate - not to the opponent panel's own visibility.
    @Published var showDeadFor = false

    // BattlegroundsBoard's children.
    @Published var minions = [Entity]()
    // NotFoughtOpponent / HeroNoMinionsOnBoard.
    @Published var notFoughtOpponent = false
    @Published var heroNoMinionsOnBoard = false
    // BattlegroundsAge.
    @Published var boardAgeText = ""
    // TiersInfo's six BattlegroundsTierTriples, tier 1 through 6.
    @Published var tiers = (1...6).map { TierTriples(tier: $0, qty: 0, turn: 0) }
    // The quest badges, empty when the opponent has none.
    @Published var quests = [Quest]()

    // Per leaderboard slot (0 = first place), the number of turns that player
    // has been dead, or nil for a slot with nobody dead in it.
    @Published var deadForSlots = [Int?](repeating: nil, count: BattlegroundsOpponentInfoViewModel.leaderboardSlots)
    // The leaderboard place of the opponent we are about to fight, whose label
    // is nudged right so it clears the hero portrait that marks them.
    @Published var nextOpponentLeaderboardPosition = 0
    @Published var isDuos = false

    // _leaderboardDeadForText.Count.
    static let leaderboardSlots = 8

    private var hoveredEntityId: Int?
    // Whether this view model was the one that took Bob's Buddy down, so it only
    // puts back a panel it hid itself.
    private var bobsBuddyHidden = false

    // OverlayWindow._leaderboardHoveredEntityId, pushed by
    // BattlegroundsLeaderboardWatcher.
    func setHoveredEntityId(_ entityId: Int?) {
        hoveredEntityId = entityId
        DispatchQueue.main.async {
            self.update()
        }
    }

    // OverlayWindow.UpdateOpponentDeadForTurns. `turns` is
    // OpponentDeadForTracker's list, longest-dead first; it is laid into the
    // slots from the bottom of the leaderboard upward, so the player who died
    // first sits in last place.
    func updateDeadForTurns(_ turns: [Int]) {
        var slots = [Int?](repeating: nil, count: Self.leaderboardSlots)
        var index = AppDelegate.instance().coreManager.game.battlegroundsHeroCount() - 1
        for turn in turns {
            if index >= 0 && index < slots.count {
                slots[index] = turn
            }
            index -= 1
        }
        deadForSlots = slots
    }

    // OverlayWindow.PositionDeadForText's only argument - the rest of that
    // method is layout, which BattlegroundsOpponentDeadForView does itself.
    func setNextOpponentLeaderboardPosition(_ position: Int) {
        nextOpponentLeaderboardPosition = position
    }

    // Called from Game.reset(), which does not guarantee the main thread.
    func reset() {
        DispatchQueue.main.async {
            self.hoveredEntityId = nil
            self.isShown = false
            self.showDeadFor = false
            self.clearBoard()
            self.deadForSlots = [Int?](repeating: nil, count: Self.leaderboardSlots)
            self.nextOpponentLeaderboardPosition = 0
        }
    }

    // OverlayWindow.UpdateBattlegroundsOverlay.
    @MainActor
    func update() {
        let game = AppDelegate.instance().coreManager.game

        isDuos = game.isBattlegroundsDuosMatch()
        showDeadFor = false

        // HDT only ever runs this from its Battlegrounds path, and its dead-for
        // labels lived on an overlay canvas that was itself only up during a
        // match. RootOverlay is up all the time, so the match term is carried
        // here instead.
        if game.turnNumber() == 0 || !game.isBattlegroundsMatch() || game.gameEnded {
            isShown = false
            return
        }

        var shouldShowOpponentInfo = false

        if let heroEntityId = hoveredEntityId {
            showDeadFor = true
            // check if it's the team mate
            if let entity = game.entities[heroEntityId], !(entity.isControlled(by: game.player.id) || (game.isBattlegroundsDuosMatch() && entity[.bacon_duo_team_id] == game.playerEntity?[.bacon_duo_team_id])) {
                shouldShowOpponentInfo = true
            }
        }

        if shouldShowOpponentInfo {
            displayHero(entityId: hoveredEntityId)
        } else {
            displayHero(entityId: nil)
        }

        // HDT keeps Bob's Buddy and the top bar up and merely fades them to 0.3
        // while the panel is out; HSTracker has always hidden them instead,
        // because its own panel is wider than HDT's and covers the same corner.
        let windowManager = game.windowManager
        if shouldShowOpponentInfo {
            game.hideBobsBuddy = true
            game.hideBattlegroundsTurn = true
            game.updateTurnCounterOverlay()

            if windowManager.bobsBuddyPanel.window?.isVisible ?? false {
                bobsBuddyHidden = true
                windowManager.show(controller: windowManager.bobsBuddyPanel, show: false)
            }
        } else {
            game.hideBobsBuddy = false
            if bobsBuddyHidden {
                bobsBuddyHidden = false
                windowManager.show(controller: windowManager.bobsBuddyPanel, show: true)
            }
            game.hideBattlegroundsTurn = false
            game.updateTurnCounterOverlay()
        }
    }

    // BgsOpponentInfo.Update / ClearLastKnownBoard, plus the hero-power push
    // HSTracker's own minion browser needs.
    @MainActor
    private func displayHero(entityId: Int?) {
        let game = AppDelegate.instance().coreManager.game

        guard Settings.showOpponentWarband,
              let entityId,
              let hero = game.entities[entityId],
              let board = game.getBattlegroundsBoardStateFor(id: hero.id),
              let player = game.player else {
            isShown = false
            clearBoard()
            return
        }

        var heroPowers = player.board.filter { x in x.isHeroPower }.compactMap { x in x.cardId }
        if heroPowers.count > 0 && game.gameEntity?[.step] ?? 0 <= Step.begin_mulligan.rawValue {
            let heroes = player.playerEntities.filter { x in x.isHero && (x.has(tag: .bacon_hero_can_be_drafted) || x.has(tag: .bacon_skin))}
            heroPowers = heroes.compactMap { x in Cards.by(dbfId: x[.hero_power], collectible: false)?.id }
        }
        game.battlegroundsMinionsOnHeroPowers(heroPowers)

        setBoard(board, game: game)
        isShown = true
    }

    @MainActor
    private func setBoard(_ board: BoardSnapshot, game: Game) {
        // turn == -1 is HSTracker's marker for a hero whose board has never been
        // seen, which is the state HDT gets by being handed a null snapshot.
        let neverFought = board.turn == -1

        minions = neverFought ? [] : board.entities
        notFoughtOpponent = neverFought
        heroNoMinionsOnBoard = !neverFought && board.entities.isEmpty
        boardAgeText = neverFought
            ? ""
            : String.localizedStringWithFormat(String.localizedString("%d turn(s) ago", comment: ""),
                                               game.turnNumber() - board.turn)

        tiers = (1...6).map { tier in
            TierTriples(tier: tier, qty: board.triples[tier - 1], turn: board.techLevel[tier - 1])
        }

        var quests = [Quest]()
        if board.questHP != 0 {
            quests.append(Quest(dbfId: board.questHP, turn: board.questHPTurn))
        }
        if board.quest != 0 {
            quests.append(Quest(dbfId: board.quest, turn: board.questTurn))
        }
        self.quests = quests
    }

    @MainActor
    private func clearBoard() {
        minions = []
        notFoughtOpponent = false
        heroNoMinionsOnBoard = false
        boardAgeText = ""
        tiers = (1...6).map { TierTriples(tier: $0, qty: 0, turn: 0) }
        quests = []
    }
}
