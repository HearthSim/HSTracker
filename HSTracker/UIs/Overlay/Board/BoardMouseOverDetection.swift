//
//  BoardMouseOverDetection.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

// OverlayWindow.MouseOverDetection's DetectMouseOver, together with the
// DelayedMouseOver it drives it through. This is what replaces the
// NSTrackingAreas the BoardOverlay panels used to carry: the RootOverlay canvas
// stays click-through, so SwiftUI's own .onHover would never fire over it, and
// the cursor has to be tested against the reported geometry instead - which is
// how HDT has always done it.
@available(macOS 10.15, *)
final class BoardMouseOverDetection {
    private unowned let viewModel: RootOverlayViewModel

    // DelayedMouseOver._current: the entity whose hover has already been
    // handled, so a cursor resting on the same minion does not re-fire.
    private var current: Entity?
    // Bumped on every new hover so a delayed callback from an older one can
    // tell it has been superseded - DelayedMouseOver gets this from comparing
    // _current by reference after the await.
    private var token = 0

    // Config.Instance.OverlayMouseOverTriggerDelay and the 200 HDT overrides it
    // with for Mercenaries, plus DelayedMouseOver's default tolerance, which is
    // compared against a *squared* distance.
    private static let triggerDelay = 0.250
    private static let mercenariesTriggerDelay = 0.200
    private static let tolerance: CGFloat = 3

    init(viewModel: RootOverlayViewModel) {
        self.viewModel = viewModel
    }

    func update(cursor: CGPoint) {
        let targets = viewModel.boardHoverTargets
        let board = viewModel.boardOverlay
        let game = AppDelegate.instance().coreManager.game

        // The overlay reports nothing while it is hidden, which stands in for
        // the IsInMenu / IsMulliganDone / foreground gate around HDT's call.
        guard !targets.isEmpty else {
            clear()
            return
        }

        let step = game.gameEntity?[.step] ?? 0
        if board.isMercenariesMatch && current != nil && step == Step.main_combat.rawValue {
            current = nil
            clearMercHover()
            clearAbilitiesVisibility()
            return
        }

        // Opponent first at each index, then the player, exactly as HDT walks
        // the two boards.
        for index in 0 ..< BoardOverlayViewModel.maxBoardSize {
            for isPlayer in [false, true] {
                guard let target = targets.first(where: { $0.kind == .minion(isPlayer: isPlayer) && $0.index == index }),
                      target.containsAsEllipse(cursor) else { continue }
                guard let side: Player = isPlayer ? game.player : game.opponent else { continue }
                let entities = BoardOverlayViewModel.board(of: side)
                guard entities.count > index else { continue }
                let entity = entities[index]
                delayed(entity,
                        delay: board.isMercenariesMatch ? Self.mercenariesTriggerDelay : Self.triggerDelay,
                        onSuccess: { [weak self] in
                            guard let self else { return }
                            if board.isMercenariesMatch {
                                if step != Step.main_combat.rawValue {
                                    self.showMercHover(entity: entity, player: side)
                                }
                                // The player's own strip steps aside while a
                                // minion is being nominated to move.
                                let exclude = isPlayer
                                    ? game.gameEntity?.has(tag: .allow_move_minion) ?? false
                                    : false
                                self.updateAbilitiesVisibility(hoverIndex: index,
                                                               boardSize: entities.count,
                                                               minions: board.minions(isPlayer: isPlayer),
                                                               excludeIndex: exclude)
                            } else {
                                self.viewModel.flavorText.setEntity(entity)
                            }
                        },
                        onMoved: { [weak self] in
                            self?.viewModel.flavorText.hide()
                            self?.clearMercHover()
                            self?.clearAbilitiesVisibility()
                        })
                return
            }
        }

        clearMercHover()
        clearAbilitiesVisibility()

        // The hand is walked back to front, so the card drawn on top wins where
        // two of them overlap.
        let handTargets = targets.filter { $0.kind == .handCard }
        for target in handTargets.sorted(by: { $0.index > $1.index }) {
            guard target.containsAsRotatedRect(cursor) else { continue }
            guard let entity = game.player?.hand.first(where: { $0[.zone_position] == target.index + 1 }) else {
                return
            }
            delayed(entity,
                    delay: Self.triggerDelay,
                    onSuccess: { [weak self] in self?.viewModel.flavorText.setEntity(entity) },
                    onMoved: { [weak self] in self?.viewModel.flavorText.hide() })
            return
        }

        clear()
    }

    // Everything DetectMouseOver does when the cursor is over nothing.
    private func clear() {
        current = nil
        token += 1
        clearMercHover()
        clearAbilitiesVisibility()
        viewModel.flavorText.hide()
    }

    // DelayedMouseOver.DelayedMouseOverDetection.
    private func delayed(_ target: Entity, delay: TimeInterval,
                         onSuccess: @escaping () -> Void, onMoved: @escaping () -> Void) {
        guard current !== target else { return }
        current = target
        token += 1
        let expected = token
        let origin = NSEvent.mouseLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.token == expected, self.current === target else { return }
            let now = NSEvent.mouseLocation
            let moved = pow(now.x - origin.x, 2) + pow(now.y - origin.y, 2)
            if moved > Self.tolerance {
                onMoved()
                self.current = nil
                return
            }
            onSuccess()
        }
    }

    // OverlayWindow.UpdateAbilitesVisibility: the tooltip opens to whichever
    // side has more room, and the strips it would cover get out of the way.
    private func updateAbilitiesVisibility(hoverIndex: Int, boardSize: Int,
                                           minions: [BoardMinionOverlayViewModel],
                                           excludeIndex: Bool) {
        let center = 0.5 * Double(boardSize + 1) - 1
        for i in 0 ..< BoardOverlayViewModel.maxBoardSize {
            let visible = Double(hoverIndex) <= center ? i <= hoverIndex : i >= hoverIndex
            if minions[i].abilitiesVisible != visible {
                minions[i].abilitiesVisible = visible
            }
        }
        if excludeIndex {
            minions[hoverIndex].abilitiesVisible = false
        }
    }

    // OverlayWindow.ClearAbilitesVisibility.
    private func clearAbilitiesVisibility() {
        for minion in viewModel.boardOverlay.opponentMinions + viewModel.boardOverlay.playerMinions
        where !minion.abilitiesVisible {
            minion.abilitiesVisible = true
        }
    }

    // OverlayWindow.ShowMercHover, which fills its three MercAbility CardImages
    // with the hovered mercenary's abilities.
    private func showMercHover(entity: Entity, player: Player) {
        let wantsHover = player.isLocalPlayer
            ? Settings.showMercsPlayerHover
            : Settings.showMercsOpponentHover
        guard wantsHover else {
            clearMercHover()
            return
        }
        // HDT bails to ClearMercHover when the hovered entity has no card id at
        // all, before it ever looks the abilities up.
        guard let id = entity.card.id as String?, !id.isEmpty else {
            clearMercHover()
            return
        }
        let data = getMercAbilities(player: player)
        guard entity.zonePosition > 0, entity.zonePosition - 1 < data.count else { return }
        let abilities = data[entity.zonePosition - 1]

        viewModel.mercenariesAbilityHover.show((0 ..< min(3, abilities.count)).compactMap { i in
            guard let card = abilities[i].entity?.card ?? abilities[i].card else { return nil }
            // ShowQuestionmark: the ability came from the remote config rather
            // than the board and has more than one tier, so which one this
            // mercenary actually has is unknown.
            return MercenariesAbilityHoverViewModel.Ability(
                id: i,
                card: card,
                showQuestionmark: abilities[i].entity == nil && abilities[i].hasTiers)
        })
    }

    // OverlayWindow.ClearMercHover.
    private func clearMercHover() {
        viewModel.mercenariesAbilityHover.clear()
    }
}
