//
//  TrackerGraveyardDetailsView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// The minion list the graveyard counter opens while the cursor is on it.
///
/// This one is HSTracker's own - HDT has no graveyard counter in its stack - and
/// used to be a second `CardList` window that `GraveyardCounter` put up from its
/// own tracking area. On the canvas it is a sibling of the tracker panel, driven
/// by the counter's hover region, which is what let `GraveyardCounter` go back to
/// being nothing but the theme's frame and two numbers.
///
/// It hangs off the far side of the tracker (to its left for the player, to its
/// right for the opponent), as the window did. The window grew upwards from the
/// cursor; this grows upwards from the counter instead, so it does not jitter
/// with the pointer inside the counter's 40pt band.
@available(macOS 10.15, *)
struct TrackerGraveyardDetailsView: View {
    @ObservedObject var viewModel: TrackerPanelViewModel
    let canvasSize: CGSize
    /// Frame of the graveyard counter in canvas pixels, as the panel reported it.
    let counterRect: CGRect?
    let isHovered: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            if isShown, let rect = counterRect {
                list
                    .frame(width: width, height: height)
                    .offset(x: viewModel.playerType == .opponent ? rect.maxX : rect.minX - width,
                            y: max(rect.maxY - height, 0))
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
    }

    private var isShown: Bool {
        viewModel.isShown && viewModel.showGraveyard && viewModel.graveyardDetails
            && isHovered && !viewModel.graveyardMinions.isEmpty
    }

    private var scale: CGFloat { CGFloat(viewModel.scaling) / 100.0 }
    private var rowHeight: CGFloat { CGFloat(Settings.cardSize.rowHeight) * scale }
    private var width: CGFloat { SizeHelper.trackerWidth * scale }
    private var height: CGFloat { rowHeight * CGFloat(viewModel.graveyardMinions.count) }

    private var list: some View {
        TrackerCardListView(content: TrackerCardListContent(cards: viewModel.graveyardMinions,
                                                            version: viewModel.graveyardVersion,
                                                            reset: false),
                            // The list the window used drew its rows as `.secrets`
                            // bars, so the details keep that look.
                            playerType: .secrets,
                            cardHeight: rowHeight,
                            // The CardList window this replaced gave its rows the
                            // same card render on hover.
                            delegate: OverlayCardListHoverHandler.cardList)
    }
}
