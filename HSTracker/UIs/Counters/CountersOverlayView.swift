//
//  CountersOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/26/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// One of HDT's two CountersOverlay controls, placed on the RootOverlay canvas
// the way OverlayWindow.xaml places them on its own - they are declared
// straight on that canvas (`<overlay:CountersOverlay x:Name="PlayerCounters"
// IsPlayer="true"/>`), not in a window of their own, which is what this
// replaces.
//
// It belongs in RootOverlayView's 1080-reference scaled subtree rather than
// its fixed-pixel chrome layer: OverlayWindow.Update.cs gives both controls
// `RenderTransform = new ScaleTransform(Height / 1080, Height / 1080)`, the
// same resolution scaling the active-effects widgets get. The AppKit windows
// this replaces were a fixed 336x102 in screen points however large the
// client was, so the counters now grow with the client the way HDT's do.
//
// Positions come from Config: PlayerCountersVertical/Horizontal (68.4/67.7)
// and OpponentCountersVertical/Horizontal (70.6/67.7), the same numbers
// SizeHelper.playerCountersFrame/opponentCountersFrame used to hold. HDT lets
// the player drag both while the overlay is unlocked and writes the new
// percentages back; HSTracker never persisted a dragged position for these
// (the frame was recomputed from SizeHelper on every refresh), so they stay
// fixed here too.
@available(macOS 10.15, *)
struct CountersOverlayView: View {
    @ObservedObject var viewModel: CountersOverlayViewModel
    // The canvas width RootOverlayView measured, in the 1080-tall reference
    // space this subtree is authored in.
    let canvasWidth: CGFloat

    private static let canvasHeight: CGFloat = 1080

    // Config.PlayerCountersVertical / PlayerCountersHorizontal.
    private static let playerVertical: CGFloat = 68.4
    private static let playerHorizontal: CGFloat = 67.7
    // Config.OpponentCountersVertical / OpponentCountersHorizontal.
    private static let opponentVertical: CGFloat = 70.6
    private static let opponentHorizontal: CGFloat = 67.7

    // CounterChipView's own fixed height, which is all the rows are made of.
    private static let chipHeight: CGFloat = 51

    // HDT's CountersOverlay.BattlegroundsWrapThreshold.
    private static let battlegroundsWrapThreshold = 2

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while the side is hidden or has no
        // counters to show, which is what replaces the old
        // `visibility && visibleCounters.count > 0` window show/hide.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown && !viewModel.chips.isEmpty {
                rowsStack
                    .offset(x: originX, y: originY)
            }
        }
        .frame(width: canvasWidth, height: Self.canvasHeight, alignment: .topLeading)
    }

    // HDT's CountersOverlay.WrapWidth, the MaxWidth it puts on the WrapPanel
    // the chips sit in: positive infinity - one row, never wrapped - unless a
    // Battlegrounds match has more counters up than the threshold, in which
    // case it is the summed width of the first ceil(count / 2) of them, so the
    // row breaks into two with the larger half on top.
    //
    // HDT sums the pills' own ActualWidth and adds InnerMargin * 2 per pill;
    // chipWidth is already that whole footprint, its 5pt margins included.
    //
    // Computed here rather than published by the view model so it is always
    // read at the same moment the rows below are, off the same chipWidths: a
    // counter's value (and with it its chip's width) settles one main-queue
    // block after the list it belongs to is republished, so anything worked out
    // at that earlier point would be a tick behind what the rows are measured
    // against.
    private var wrapWidth: CGFloat {
        let chips = viewModel.chips
        guard viewModel.isBattlegroundsMatch, chips.count > Self.battlegroundsWrapThreshold else {
            return .infinity
        }
        let maxPerRow = Int(ceil(Double(chips.count) / 2.0))
        return chips.prefix(maxPerRow).reduce(0) { $0 + $1.chipWidth }
    }

    // Greedily wraps chips into rows no wider than wrapWidth, stacking overflow
    // rows below the first - what WrapPanel does with that MaxWidth. The first
    // row filled is the one closest to the anchored edge (row 0 at the higher
    // y, each subsequent row lower), which a plain top-to-bottom VStack
    // reproduces directly.
    private var rows: [[CounterChipViewModel]] {
        let wrapWidth = self.wrapWidth
        var rows: [[CounterChipViewModel]] = []
        var current: [CounterChipViewModel] = []
        var width: CGFloat = 0
        for chip in viewModel.chips {
            let chipWidth = chip.chipWidth
            if width + chipWidth > wrapWidth && !current.isEmpty {
                rows.append(current)
                current = []
                width = 0
            }
            current.append(chip)
            width += chipWidth
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    private var rowsStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(row) { chip in
                        CounterChipView(viewModel: chip)
                    }
                }
            }
        }
        // No width of its own: WrapPanel's MaxWidth only bounds where the rows
        // break (which `rows` has already applied), and the block is anchored
        // by its left edge, so its laid-out width is whatever the widest row
        // needs.
    }

    // Canvas.SetLeft(counters, Helper.GetScaledXPos(horizontal / 100, Width,
    // ScreenRatio)). The ratio is derived from the canvas rather than read off
    // SizeHelper so this stays a pure function of what RootOverlayView measured;
    // it is the same number either way, since the canvas has the client's
    // aspect ratio.
    private var originX: CGFloat {
        let horizontal = viewModel.isPlayer ? Self.playerHorizontal : Self.opponentHorizontal
        let ratio = (4.0 / 3.0) / (canvasWidth / Self.canvasHeight)
        return SizeHelper.getScaledXPos(horizontal / 100.0, width: canvasWidth, ratio: ratio)
    }

    // The player's counters hang from their top edge:
    //   Canvas.SetTop(PlayerCounters, Height * PlayerCountersVertical / 100)
    // the opponent's from their bottom, so extra rows grow upwards:
    //   Canvas.SetTop(OpponentCounters,
    //                 Height - (ActualHeight * scale
    //                           + Height * OpponentCountersVertical / 100))
    // Height here is the scaled subtree's own 1080, and ActualHeight is the
    // laid-out row stack, whose height is exactly one chip per row.
    private var originY: CGFloat {
        if viewModel.isPlayer {
            return Self.canvasHeight * Self.playerVertical / 100.0
        }
        let contentHeight = CGFloat(rows.count) * Self.chipHeight
        return Self.canvasHeight - (contentHeight + Self.canvasHeight * Self.opponentVertical / 100.0)
    }
}
