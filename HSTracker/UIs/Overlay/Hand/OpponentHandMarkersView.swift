//
//  OpponentHandMarkersView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's ten CardMarkers - Marks0 through Marks9 - placed straight on the
// overlay canvas over the opponent's hand. Replaces the 400x90 CardHudContainer
// NSPanel that held HSTracker's ten CardHud views.
//
// Belongs in RootOverlayView's fixed-pixel layer: OverlayWindow positions each
// marker from plain fractions of the client size and scales them only by the
// user's own OverlayOpponentScaling, never by the client's resolution.
@available(macOS 10.15, *)
struct OpponentHandMarkersView: View {
    @ObservedObject var viewModel: OpponentHandMarkersViewModel
    let canvasSize: CGSize

    // The width UpdateOverlay centres each marker on, and the height it offsets
    // it by a third of. Both are the control's own size before
    // OverlayOpponentScaling, which HSTracker has no counterpart for - so the
    // scaling factor is 1 throughout and drops out.
    private static let markerWidth: CGFloat = 36
    private static let markerHeight: CGFloat = 34

    // The floor UpdateOverlay clamps the top to, so a marker never leaves the
    // client at the top.
    private static let minimumTop: CGFloat = 5

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while hidden, which is what replaces
        // the window show/hide.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown, let row = positions {
                ForEach(0 ..< row.count, id: \.self) { index in
                    marker(index: index, position: row[index])
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        // Purely a hover surface - it must never take a click away from
        // Hearthstone. The tooltip it raises is driven by RootOverlayWindow's
        // cursor sweep, which works while the canvas stays click-through.
        .allowsHitTesting(false)
    }

    private var positions: [CGPoint]? {
        let count = viewModel.handCount
        guard count > 0, count <= OpponentHandMarkersViewModel.maxHandSize else { return nil }
        return OpponentHandMarkersViewModel.positions[count - 1]
    }

    private func marker(index: Int, position: CGPoint) -> some View {
        // The hover tooltip is attached inside CardMarkerView, which is what
        // observes the marker's own view model.
        CardMarkerView(viewModel: viewModel.markers[index])
            .offset(x: left(position), y: top(position))
    }

    // Canvas.SetLeft(mark, GetScaledXPos(pos.X, Width, ScreenRatio) - width / 2).
    private func left(_ position: CGPoint) -> CGFloat {
        let ratio = canvasSize.width > 0
            ? (4.0 / 3.0) / (canvasSize.width / canvasSize.height)
            : 1
        return SizeHelper.getScaledXPos(position.x, width: canvasSize.width, ratio: ratio)
            - Self.markerWidth / 2
    }

    // Canvas.SetTop(mark, Math.Max(pos.Y * Height - height / 3, 5)).
    private func top(_ position: CGPoint) -> CGFloat {
        max(position.y * canvasSize.height - Self.markerHeight / 3, Self.minimumTop)
    }
}
