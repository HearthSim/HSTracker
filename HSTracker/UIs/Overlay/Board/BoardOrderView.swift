//
//  BoardOrderView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/24/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's GridOpponentBoardOrder, GridPlayerBoardOrder, OpponentWeaponOrder and
// PlayerWeaponOrder: a numbered badge over every minion and weapon, counting
// the order they entered the board in.
//
// Deliberately separate from BoardOverlayView: that one's slots feed mouse-over
// detection by index, which the drop-gap spacer here would shift.
//
// Belongs in RootOverlayView's fixed-pixel layer: OverlayWindow places all four
// with plain fractions of the client size and never gives any a ScaleTransform.
struct BoardEntryOrderView: View {
    @ObservedObject var viewModel: BoardEntryOrderViewModel
    let canvasSize: CGSize

    private static let playerWeaponBadgeOffsetX: CGFloat = 0.364
    private static let playerWeaponBadgeCenterY: CGFloat = 0.7
    private static let opponentWeaponBadgeOffsetX: CGFloat = 0.380
    private static let opponentWeaponBadgeCenterY: CGFloat = 0.144

    private var boardHeight: CGFloat { BoardOverlayView.boardHeight(canvasSize) }
    private var minionWidth: CGFloat { BoardOverlayView.minionWidth(canvasSize) }

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while hidden.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown {
                // The board order only shows in traditional Hearthstone, so
                // the Mercenaries offsets UpdateBoardPosition also handles
                // never apply to the tops copied from the board grids here.
                row(viewModel.opponent)
                    .offset(y: BoardOverlayView.opponentTop(canvasSize, isMercenariesMatch: false,
                                                            isMainAction: false, mercsToNominate: false))
                row(viewModel.player)
                    .offset(y: BoardOverlayView.playerTop(canvasSize, isMercenariesMatch: false,
                                                          isMainAction: false, mercsToNominate: false))
                weaponBadge(viewModel.opponent.weapon,
                            offsetX: Self.opponentWeaponBadgeOffsetX,
                            centerY: Self.opponentWeaponBadgeCenterY)
                weaponBadge(viewModel.player.weapon,
                            offsetX: Self.playerWeaponBadgeOffsetX,
                            centerY: Self.playerWeaponBadgeCenterY)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    // BoardOrderView: a StackPanel Orientation="Horizontal"
    // HorizontalAlignment="Center" of the eight slots, in a grid BoardWidth
    // wide and BoardHeight tall. Collapsed slots take no space, so the visible
    // ones stay centred over the minions however many there are.
    private func row(_ side: BoardOrderViewModel) -> some View {
        let margin = BoardOverlayView.minionMargin(canvasSize, isMercenariesMatch: false)
        return HStack(spacing: 0) {
            ForEach(0 ..< BoardOrderViewModel.slotCount, id: \.self) { index in
                BoardOrderSlotView(viewModel: side.slots[index],
                                   width: minionWidth,
                                   height: boardHeight,
                                   margin: margin)
            }
        }
        .frame(width: canvasSize.width, height: boardHeight)
    }

    // PositionWeaponOrderBadges. HDT sets the slot's top-left so that the
    // badge, BadgeSize tall and overhanging the slot by BadgeOverhangFactor of
    // that, comes out centred on (GetScaledXPos(offsetX), centerY * Height);
    // the badge is placed on that centre directly here.
    private func weaponBadge(_ slot: BoardOrderSlotViewModel, offsetX: CGFloat, centerY: CGFloat) -> some View {
        let x = SizeHelper.getScaledXPos(offsetX, width: canvasSize.width,
                                         ratio: BoardOverlayView.ratio(canvasSize))
        return BoardOrderBadgeHost(viewModel: slot, height: boardHeight)
            .position(x: x, y: centerY * canvasSize.height)
    }
}

// HDT's BoardOrderSlotView: a Width x Height slot with the badge hanging off
// the top of it, horizontally centred.
struct BoardOrderSlotView: View {
    @ObservedObject var viewModel: BoardOrderSlotViewModel
    let width: CGFloat
    let height: CGFloat
    // The slot's own Margin, MinionMargin either side, as on the board grids.
    let margin: CGFloat

    var body: some View {
        // SlotVisibility is Collapsed rather than Hidden, so an unoccupied
        // slot, margins and all, takes no room in the row.
        if viewModel.isOccupied {
            Color.clear
                .frame(width: width, height: height)
                // BadgeMargin: a negative top margin, so the badge rides above
                // the slot without moving it.
                .overlay(badge, alignment: .top)
                .padding(.horizontal, margin)
        }
    }

    @ViewBuilder
    private var badge: some View {
        if let label = viewModel.label, !label.isEmpty {
            BoardOrderBadge(label: label, height: height)
                .offset(y: BoardOrderSlotViewModel.badgeTopMargin(height: height))
        }
    }
}

// A weapon's slot is never shown as a row member, only as its badge.
private struct BoardOrderBadgeHost: View {
    @ObservedObject var viewModel: BoardOrderSlotViewModel
    let height: CGFloat

    var body: some View {
        if viewModel.isOccupied, let label = viewModel.label, !label.isEmpty {
            BoardOrderBadge(label: label, height: height)
        }
    }
}

// The Border: a black pill with a 1px white outline, at least as wide as it
// is tall, and a bold white number.
private struct BoardOrderBadge: View {
    let label: String
    // The slot's Height, which BadgeSize and FontSize derive from.
    let height: CGFloat

    var body: some View {
        let badgeSize = BoardOrderSlotViewModel.badgeSize(height: height)
        Text(verbatim: label)
            .font(.system(size: BoardOrderSlotViewModel.fontSize(height: height), weight: .bold))
            .foregroundColor(.white)
            .fixedSize()
            .padding(EdgeInsets(top: 0, leading: 4, bottom: 1, trailing: 4))
            .frame(minWidth: badgeSize)
            .frame(height: badgeSize)
            .background(Capsule().fill(Color.black))
            .overlay(Capsule().strokeBorder(Color.white, lineWidth: 1))
    }
}
