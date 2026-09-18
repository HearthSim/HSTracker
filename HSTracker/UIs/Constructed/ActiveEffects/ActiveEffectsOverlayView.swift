//
//  ActiveEffectsOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// One of HDT's two ActiveEffectsOverlay controls, placed on the RootOverlay
// canvas the way OverlayWindow.xaml places them on its own - they are declared
// straight on that canvas next to the counters, not in a window of their own,
// which is what this replaces.
//
// It belongs in RootOverlayView's 1080-reference scaled subtree rather than its
// fixed-pixel chrome layer: OverlayWindow.Update.cs gives both controls
// `RenderTransform = new ScaleTransform(Height / 1080, Height / 1080)` - the
// _activeEffectsScale the counters and the resources widgets share. The AppKit
// windows this replaces were a fixed 244x122 in screen points however large the
// client was, so the tiles now grow with the client the way HDT's do.
//
// Positions come from Settings, which start at HDT's own defaults:
// PlayerActiveEffectsVertical/Horizontal (71.6/66.2) and
// OpponentActiveEffectsVertical/Horizontal (73.8/66.2), the same numbers
// SizeHelper.playerActiveEffectsFrame/opponentActiveEffectsFrame used to hold.
// Both blocks can be dragged while the overlay is unlocked, as HDT's can - see
// OverlayWidgetPlacement.
struct ActiveEffectsOverlayView: View {
    @ObservedObject var viewModel: ActiveEffectsOverlayViewModel
    // Observed as well as the view model: a drag moves the tiles without
    // anything about the effects themselves changing.
    @ObservedObject var placement: OverlayWidgetPlacement
    // The canvas width RootOverlayView measured, in the 1080-tall reference
    // space this subtree is authored in.
    let canvasWidth: CGFloat
    // The canvas's real, post-scale size, which the drag's percentages are
    // taken against - the Width/Height of HDT's own overlay window.
    let canvasSize: CGSize
    // `Settings.windowsLocked`, HDT's `_uiMovable` inverted.
    let isLocked: Bool

    private static let canvasHeight: CGFloat = 1080

    // HDT's MaxColumns, and the two rows its MaxHeight budgets for.
    private static let maxColumns = 4
    private static let maxRows = 2

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while the side is hidden or has no
        // effect to show, which is what replaces the old window show/hide.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown && !viewModel.effects.isEmpty {
                grid
                    .offset(x: originX, y: originY)
                // HDT paints a box over every movable element while the overlay
                // is unlocked and drags it from there (OverlayWindow.Input.cs).
                if !isLocked {
                    OverlayWidgetMovableBox(placement: placement, frame: contentFrame,
                                            canvasSize: canvasSize)
                }
            }
        }
        .frame(width: canvasWidth, height: Self.canvasHeight, alignment: .topLeading)
    }

    /// What the tiles currently occupy, in reference-space points - the
    /// UniformGrid's own laid-out size, one cell per column and row.
    private var contentFrame: CGRect {
        let rows = self.rows
        let columns = rows.map { $0.count }.max() ?? 0
        return CGRect(x: originX, y: originY,
                      width: CGFloat(columns) * ActiveEffectView.cellSize,
                      height: CGFloat(rows.count) * ActiveEffectView.cellSize)
    }

    // HDT's UniformGrid with Columns="{Binding ColumnCount}", ColumnCount being
    // min(MaxColumns, VisibleEffects.Count) - which for anything past the first
    // row is just rows of four. Capped at two rows, as the AppKit grid was and
    // as HDT's MaxHeight budgets for; HDT wraps the grid in a ScrollViewer for
    // the overflow, which HSTracker has never had.
    private var rows: [[ActiveEffectViewModel]] {
        let effects = Array(viewModel.effects.prefix(Self.maxColumns * Self.maxRows))
        return stride(from: 0, to: effects.count, by: Self.maxColumns).map {
            Array(effects[$0 ..< min($0 + Self.maxColumns, effects.count)])
        }
    }

    private var grid: some View {
        // For the opponent HDT mirrors the whole grid vertically (ScaleY="-1"
        // on the outer Grid, undone on each item so the tiles stay upright),
        // which puts the first row at the bottom and grows the overflow row
        // upwards. Reversing the rows here is that mirror, without having to
        // flip each tile back.
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array((viewModel.isPlayer ? rows : rows.reversed()).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(row) { effect in
                        ActiveEffectView(viewModel: effect)
                    }
                }
            }
        }
    }

    // Canvas.SetLeft(overlay, Helper.GetScaledXPos(horizontal / 100, Width,
    // ScreenRatio)). The ratio is derived from the canvas rather than read off
    // SizeHelper so this stays a pure function of what RootOverlayView
    // measured; it is the same number either way, since the canvas has the
    // client's aspect ratio.
    private var originX: CGFloat {
        let ratio = (4.0 / 3.0) / (canvasWidth / Self.canvasHeight)
        return SizeHelper.getScaledXPos(CGFloat(placement.horizontal) / 100.0,
                                        width: canvasWidth, ratio: ratio)
    }

    // The player's effects hang from their top edge:
    //   Canvas.SetTop(PlayerActiveEffects, Height * PlayerActiveEffectsVertical / 100)
    // the opponent's from their bottom, so a second row grows upwards:
    //   Canvas.SetTop(OpponentActiveEffects,
    //                 Height - (ActualHeight * scale
    //                           + Height * OpponentActiveEffectsVertical / 100))
    // Height here is the scaled subtree's own 1080, and ActualHeight is the
    // laid-out grid, whose height is exactly one cell per row.
    private var originY: CGFloat {
        if viewModel.isPlayer {
            return Self.canvasHeight * CGFloat(placement.vertical) / 100.0
        }
        let contentHeight = CGFloat(rows.count) * ActiveEffectView.cellSize
        return Self.canvasHeight - (contentHeight + Self.canvasHeight * CGFloat(placement.vertical) / 100.0)
    }
}
