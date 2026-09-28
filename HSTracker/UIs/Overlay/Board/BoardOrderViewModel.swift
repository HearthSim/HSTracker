//
//  BoardOrderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/24/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// HDT's BoardOrderRanker: turns each on-screen entity's BoardOrder - the
// running count of entries into PLAY, which keeps climbing across the whole
// game - into its rank among what is on the board right now, 1 being the
// longest-standing.
final class BoardOrderRanker {
    // Reused across updates. Safe because every caller runs on the main
    // thread, the watcher's changes included.
    private var onScreen: [(id: Int, order: Int)] = []
    private var ranks: [Int: Int] = [:]

    func compute(game: Game,
                 friendlyZone: PlayZoneArgs?, friendlyWeapon: Entity?,
                 opposingZone: PlayZoneArgs?, opposingWeapon: Entity?) -> [Int: Int] {
        onScreen.removeAll(keepingCapacity: true)
        collect(game: game, zone: friendlyZone, weapon: friendlyWeapon)
        collect(game: game, zone: opposingZone, weapon: opposingWeapon)

        onScreen.sort { $0.order < $1.order }

        ranks.removeAll(keepingCapacity: true)
        for (i, entry) in onScreen.enumerated() {
            ranks[entry.id] = i + 1
        }
        return ranks
    }

    private func collect(game: Game, zone: PlayZoneArgs?, weapon: Entity?) {
        if let cards = zone?.boardCards {
            for card in cards {
                if let id = card.entityId?.intValue,
                   let entity = game.entities[id],
                   let order = entity.info.boardOrder {
                    onScreen.append((id, order))
                }
            }
        }

        // Weapons are not in the play zone but share the sequence with minions.
        if let weapon, let weaponOrder = weapon.info.boardOrder {
            onScreen.append((weapon.id, weaponOrder))
        }
    }
}

// HDT's BoardOrderSlotViewModel: one board position, and the badge over it.
// The geometry HDT stores here (Width, Height, Margin and what derives from
// them) is worked out from the canvas size by the view instead, the way the
// rest of the board ports do it - only what comes off the game is published.
final class BoardOrderSlotViewModel: ObservableObject {
    // SlotVisibility: an unoccupied slot is Collapsed and takes no space.
    @Published private(set) var isOccupied = false

    // LabelVisibility is Collapsed while this is nil or empty.
    @Published private(set) var label: String?

    static let badgeSizeFactor: CGFloat = 0.14

    static let badgeOverhangFactor: CGFloat = 0.6

    // BadgeSize, FontSize and BadgeMargin, from the slot's Height.
    static func badgeSize(height: CGFloat) -> CGFloat { height * badgeSizeFactor }

    static func fontSize(height: CGFloat) -> CGFloat { max(1.0, badgeSize(height: height) * 0.6) }

    static func badgeTopMargin(height: CGFloat) -> CGFloat { -badgeSize(height: height) * badgeOverhangFactor }

    // Only republish on a real change: the board is refreshed on every GUI
    // tick and on every watcher tick, and an unconditional assignment would
    // redraw every badge each time.
    func set(isOccupied: Bool, label: String?) {
        if self.isOccupied != isOccupied {
            self.isOccupied = isOccupied
        }
        if self.label != label {
            self.label = label
        }
    }
}

// HDT's BoardOrderViewModel: one side's row of badges, plus that side's weapon.
final class BoardOrderViewModel: ObservableObject {
    // 7 board positions plus one spacer for the drop gap.
    static let slotCount = 8

    private static func rankLabel(_ rank: Int) -> String { String(rank) }

    let slots = (0 ..< slotCount).map { _ in BoardOrderSlotViewModel() }

    let weapon = BoardOrderSlotViewModel()

    func clear() {
        for slot in slots {
            slot.set(isOccupied: false, label: nil)
        }
        weapon.set(isOccupied: false, label: nil)
    }

    func update(zone: PlayZoneArgs?, weapon: Entity?, ranks: [Int: Int]) {
        // HDT clears every slot and then fills in the occupied ones; worked
        // out into locals first here so a slot that stays the same publishes
        // nothing.
        var occupied = [Bool](repeating: false, count: slots.count)
        var labels = [String?](repeating: nil, count: slots.count)

        self.weapon.set(isOccupied: weapon != nil,
                        label: weapon.flatMap { ranks[$0.id] }.map(Self.rankLabel))

        if let zone {
            let cards = zone.boardCards
            if zone.mousedOverSlot > 0 && zone.mousedOverSlot <= slots.count {
                occupied[zone.mousedOverSlot - 1] = true
            }

            for (i, card) in cards.enumerated() {
                let oneBasedIndex = i + 1
                let targetPos = zone.mousedOverSlot > 0 && oneBasedIndex >= zone.mousedOverSlot
                    ? oneBasedIndex + 1
                    : oneBasedIndex

                let targetIdx = targetPos - 1
                if targetIdx < 0 || targetIdx >= slots.count {
                    continue
                }

                occupied[targetIdx] = true
                if let entityId = card.entityId?.intValue, let rank = ranks[entityId] {
                    labels[targetIdx] = Self.rankLabel(rank)
                }
            }
        }

        for (i, slot) in slots.enumerated() {
            slot.set(isOccupied: occupied[i], label: labels[i])
        }
    }
}

// The board entry order half of HDT's OverlayWindow: GridOpponentBoardOrder,
// GridPlayerBoardOrder and the two weapon badges, and the state
// UpdateBoardOrderOverlay draws them from. Main thread only.
final class BoardEntryOrderViewModel: ObservableObject {
    // The two BoardOrderViewModels' Visibility, which HDT always sets together.
    @Published private(set) var isShown = false

    let player = BoardOrderViewModel()
    let opponent = BoardOrderViewModel()

    private var lastBoardState: BoardStateArgs?
    // Weapons only ever change through the log, so they are cached by the log
    // side's update and the watcher path stays free of entity scans.
    private var playerWeapon: Entity?
    private var opponentWeapon: Entity?
    private let ranker = BoardOrderRanker()

    // OverlayWindow.OnPlayZoneStateChanged.
    func onPlayZoneStateChanged(_ args: BoardStateArgs, game: Game, isContentVisible: Bool) {
        lastBoardState = args
        update(game: game, isContentVisible: isContentVisible)
    }

    // The tail of OverlayWindow.UpdateBoardState. The watcher only fires when
    // the zone contents change, so refresh here too: a BoardOrder assigned by
    // the log slightly after the last tick would otherwise leave a minion
    // unlabelled until the board next changes.
    func onBoardStateUpdated(playerWeapon: Entity?, opponentWeapon: Entity?, game: Game,
                             isContentVisible: Bool) {
        self.playerWeapon = playerWeapon
        self.opponentWeapon = opponentWeapon
        update(game: game, isContentVisible: isContentVisible)
    }

    // OverlayWindow.UpdateBoardOrderOverlay. isContentVisible is
    // OverlayWindow.IsContentVisible, which is false while the overlay is
    // hidden - the caller works out the one condition that hides it mid-game.
    private func update(game: Game, isContentVisible: Bool) {
        let show = Settings.showBoardEntryOrder
            && game.isTraditionalHearthstoneMatch
            && game.isMulliganDone()
            && !game.isInMenu
            && !Self.isGameOver(game)
            && isContentVisible

        if !show {
            // Only clear on the transition. This runs on every GUI tick, and
            // both view models start out in the cleared state, so re-clearing
            // is pure notification churn for everyone who never turns the
            // setting on.
            if !isShown {
                return
            }
            isShown = false
            player.clear()
            opponent.clear()
            return
        }

        if !isShown {
            isShown = true
        }

        let ranks = ranker.compute(game: game,
                                   friendlyZone: lastBoardState?.friendly, friendlyWeapon: playerWeapon,
                                   opposingZone: lastBoardState?.opposing, opposingWeapon: opponentWeapon)

        player.update(zone: lastBoardState?.friendly, weapon: playerWeapon, ranks: ranks)
        opponent.update(zone: lastBoardState?.opposing, weapon: opponentWeapon, ranks: ranks)
    }

    // OverlayWindow.IsGameOver.
    private static func isGameOver(_ game: Game) -> Bool {
        guard let gameEntity = game.gameEntity else { return true }
        return game.isInMenu || gameEntity[.state] == State.complete.rawValue
    }
}
