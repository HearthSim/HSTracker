//
//  BattlegroundsOpponentDeadForView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's eight BattlegroundsTileText/BattlegroundsTurnText pairs
// (Windows/OverlayWindow.xaml) and the layout OverlayWindow.PositionDeadForText
// gives them: over each leaderboard slot, how many turns that player has been
// dead, with "Turn"/"Turns" underneath.
//
// These are plain children of HDT's overlay canvas with no OverlayElementBehavior
// of their own, so they take no resolution scaling: their FontSize is a literal
// 15 in real window pixels while their positions are fractions of the window's
// own height. That is why this lives in RootOverlayView's fixed-pixel chrome
// layer rather than its 1080-reference scaled subtree, and why it takes the
// canvas's real size.
@available(macOS 10.15, *)
struct BattlegroundsOpponentDeadForView: View {
    @ObservedObject var viewModel: BattlegroundsOpponentInfoViewModel
    let canvasSize: CGSize

    // The per-slot Margins the eight pairs carry in OverlayWindow.xaml, which
    // nudge each label onto the leaderboard portrait it belongs to (the
    // leaderboard is drawn in perspective, so no two slots line up the same
    // way). x is the Margin's Left, y its Top.
    private static let tileTextMargins: [CGPoint] = [
        CGPoint(x: 2, y: -13),
        CGPoint(x: 2, y: -14),
        CGPoint(x: 1, y: -15),
        CGPoint(x: 0.5, y: -15),
        CGPoint(x: 0, y: -13),
        CGPoint(x: -2, y: -14),
        CGPoint(x: -1.5, y: -13),
        CGPoint(x: -2.5, y: -11)
    ]
    private static let turnTextMargins: [CGPoint] = [
        CGPoint(x: 2.5, y: 0),
        CGPoint(x: 2.5, y: -2),
        CGPoint(x: 2, y: -3),
        CGPoint(x: 0.5, y: -3),
        CGPoint(x: 0.5, y: -1),
        CGPoint(x: -1.5, y: -2),
        CGPoint(x: -1, y: -1),
        CGPoint(x: -2, y: 1)
    ]

    // OverlayWindow.MouseOverDetection.cs:
    //   LeftAdjust - shifts each label left by its distance down the leaderboard
    //   NextOpponentRightAdjust / DuosNextOpponentRightAdjust - shifts the next
    //   opponent's label right so it clears the portrait that marks them
    private static let leftAdjust: CGFloat = 0.0017
    private static let nextOpponentRightAdjust: CGFloat = 0.023
    private static let duosNextOpponentRightAdjust: CGFloat = 0.015

    // OverlayWindow's own leaderboard geometry.
    private static let duosTileToSpacingRatio: CGFloat = 0.137

    private var leaderboardTop: CGFloat { canvasSize.height * 0.15 }
    private var tileHeight: CGFloat { canvasSize.height * 0.69 / 8 }
    private var tileWidth: CGFloat { tileHeight }
    private var duosTileHeight: CGFloat {
        canvasSize.height * 0.69 * (1 - Self.duosTileToSpacingRatio) / 8
    }
    private var duosSpacingHeight: CGFloat {
        canvasSize.height * 0.69 * Self.duosTileToSpacingRatio / 3
    }
    // Helper.GetScaledXPos' ScreenRatio.
    private var screenRatio: CGFloat {
        guard canvasSize.height > 0, canvasSize.width > 0 else { return 1 }
        return (4.0 / 3.0) / (canvasSize.width / canvasSize.height)
    }

    var body: some View {
        // Instantiated unconditionally by RootOverlayView so the @ObservedObject
        // binding keeps driving it; it draws nothing while no leaderboard hero
        // is hovered.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.showDeadFor {
                ForEach(0..<BattlegroundsOpponentInfoViewModel.leaderboardSlots, id: \.self) { slot in
                    labels(for: slot)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func labels(for slot: Int) -> some View {
        let turns = viewModel.deadForSlots[slot]
        let origin = CGPoint(x: left(for: slot), y: top(for: slot))
        let tileMargin = Self.tileTextMargins[slot]
        let turnMargin = Self.turnTextMargins[slot]

        // Both blocks are Width="{BattlegroundsTileWidth}"
        // Height="{BattlegroundsTileHeight}" TextAlignment="Center": centred
        // across the tile's width, drawn from the top of a tile-tall box - which
        // is what leaves the "Turns" line sitting under the number.
        label(turns.map { "\($0)" } ?? "")
            .offset(x: origin.x + tileMargin.x, y: origin.y + tileMargin.y)

        // FontStretch="UltraCondensed" TextTrimming="CharacterEllipsis" - the
        // stretch has no effect on ChunkFive, which ships a single width.
        label(turns.map { $0 == 1
            ? String.localizedString("Turn", comment: "")
            : String.localizedString("Turns", comment: "") } ?? "")
            .lineLimit(1)
            .truncationMode(.tail)
            .offset(x: origin.x + turnMargin.x, y: origin.y + turnMargin.y)
    }

    private func label(_ text: String) -> some View {
        Text(verbatim: text)
            .chunkFive(size: 15)
            .outlinedText()
            .frame(width: tileWidth, alignment: .center)
            .frame(height: tileHeight, alignment: .top)
    }

    // Canvas.SetTop from PositionDeadForText.
    private func top(for slot: Int) -> CGFloat {
        if viewModel.isDuos {
            let team = slot / 2
            return leaderboardTop + duosTileHeight * CGFloat(slot) + duosSpacingHeight * CGFloat(team)
        }
        return leaderboardTop + tileHeight * CGFloat(slot)
    }

    // Canvas.SetLeft from PositionDeadForText, via Helper.GetScaledXPos.
    private func left(for slot: Int) -> CGFloat {
        let slots = BattlegroundsOpponentInfoViewModel.leaderboardSlots
        var left = CGFloat((slots / 2) - slot) * Self.leftAdjust
        if viewModel.isDuos {
            if slot / 2 == viewModel.nextOpponentLeaderboardPosition - 1 {
                left += Self.duosNextOpponentRightAdjust
            }
        } else if slot == viewModel.nextOpponentLeaderboardPosition - 1 {
            left += Self.nextOpponentRightAdjust
        }
        return SizeHelper.getScaledXPos(left, width: canvasSize.width, ratio: screenRatio)
    }
}
