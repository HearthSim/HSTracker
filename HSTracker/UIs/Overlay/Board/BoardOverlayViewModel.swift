//
//  BoardOverlayViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's BoardMinionOverlayViewModel: one of the seven slots per side. The
// geometry HDT stores here (Width, Height, Margin) is derived from the canvas
// size by the view instead, the way the rest of these ports do it - only what
// comes off the game is published.
@available(macOS 10.15, *)
final class BoardMinionOverlayViewModel: ObservableObject {
    // HDT's AbilityAlignment, which decides whether the ability strip hangs
    // above the minion or below it. The opponent's is Top, the player's Bottom.
    enum AbilityAlignment {
        case top
        case bottom
    }

    let abilityAlignment: AbilityAlignment

    // Visibility: a slot is shown only while a minion actually stands in it.
    @Published var isShown = false

    // MercenariesAbilities.
    @Published var abilities: [MercenariesAbilityModel] = []

    // AbilitiesVisibility, which is Visible/Hidden rather than Collapsed - the
    // strips that would sit under the hover tooltip step out of the way without
    // the others moving. See BoardMouseOverDetection.updateAbilitiesVisibility.
    @Published var abilitiesVisible = true

    init(abilityAlignment: AbilityAlignment) {
        self.abilityAlignment = abilityAlignment
    }
}

// The pair of board grids, GridOpponentBoard and GridPlayerBoard, and the state
// OverlayWindow reads to place them. Replaces the two BoardOverlay NSPanels.
@available(macOS 10.15, *)
final class BoardOverlayViewModel: ObservableObject {
    static let maxBoardSize = 7
    static let maxHandSize = 10

    // Game.updateBoardOverlay's gate, which HDT spells as the condition on its
    // DetectMouseOver call plus IsGameOver.
    @Published var isShown = false

    // The three game reads UpdateBoardPosition makes, published so the view can
    // derive its offsets from the canvas size without reaching for the game.
    @Published var isMercenariesMatch = false
    @Published var isMainAction = false
    @Published var mercsToNominate = false

    // Player.HandCount, for the hand hover regions.
    @Published var handCount = 0

    private var updated: Date?

    let opponentMinions = (0 ..< maxBoardSize).map { _ in
        BoardMinionOverlayViewModel(abilityAlignment: .top)
    }
    let playerMinions = (0 ..< maxBoardSize).map { _ in
        BoardMinionOverlayViewModel(abilityAlignment: .bottom)
    }

    func minions(isPlayer: Bool) -> [BoardMinionOverlayViewModel] {
        isPlayer ? playerMinions : opponentMinions
    }

    // OverlayWindow.UpdateMouseOverDetectionRegions' slot visibility, together
    // with the ability lists its debounced update assigns.
    func update(player: Player, opponent: Player, isGameOver: Bool) {
        // HDT debounces its own update by 50ms and the AppKit board overlay
        // throttled to the same, which matters here because getMercAbilities
        // below walks every entity either player owns and this runs on every
        // GUI tick.
        if let updated, updated.timeIntervalSinceNow > -0.05 {
            return
        }
        updated = Date()

        let game = AppDelegate.instance().coreManager.game
        let step = game.gameEntity?[.step] ?? 0
        isMercenariesMatch = game.isMercenariesMatch()
        isMainAction = step == Step.main_action.rawValue
            || step == Step.main_post_action.rawValue
            || step == Step.main_pre_action.rawValue
        mercsToNominate = game.gameEntity?.has(tag: .allow_move_minion) ?? false
        handCount = isGameOver ? 0 : player.handCount

        // HDT's own gate is narrower than the one UpdateBoardPosition uses: no
        // ability icons during MAIN_POST_ACTION.
        let showAbilities = isMercenariesMatch
            && (step == Step.main_action.rawValue || step == Step.main_pre_action.rawValue)
        let opponentAbilities = showAbilities && Settings.showMercsOpponentAbilities
            ? getMercAbilities(player: opponent) : nil
        let playerAbilities = showAbilities && Settings.showMercsPlayerAbilities
            ? getMercAbilities(player: player) : nil

        assign(opponentMinions, board: Self.board(of: opponent), abilities: opponentAbilities,
               isGameOver: isGameOver)
        assign(playerMinions, board: Self.board(of: player), abilities: playerAbilities,
               isGameOver: isGameOver)
    }

    // HideMercenariesGameOverlay.
    func clearAbilities() {
        for minion in opponentMinions + playerMinions {
            minion.abilities = []
        }
    }

    static func board(of player: Player) -> [Entity] {
        player.board
            .filter { $0.takesBoardSlot }
            .sorted { $0.zonePosition < $1.zonePosition }
    }

    private func assign(_ minions: [BoardMinionOverlayViewModel], board: [Entity],
                        abilities: [[MercAbilityData]]?, isGameOver: Bool) {
        for i in 0 ..< Self.maxBoardSize {
            let minion = minions[i]
            let shown = board.count > i && !isGameOver
            if minion.isShown != shown {
                minion.isShown = shown
            }
            let models = abilities?.count ?? 0 > i
                ? abilities![i].enumerated().map { MercenariesAbilityModel(id: $0.offset, data: $0.element) }
                : []
            // Only republish when something actually changed: this runs on every
            // GUI tick, and an unconditional assignment would redraw every disc
            // (and restart its art load) several times a second.
            if minion.abilities != models {
                minion.abilities = models
            }
        }
    }
}
