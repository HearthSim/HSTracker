//
//  SecretsPanelView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// HDT's `SecretsContainer`, on the RootOverlay canvas - see
/// `SecretsPanelViewModel` for the placement it carries.
@available(macOS 10.15, *)
struct SecretsPanelView: View {
    @ObservedObject var viewModel: SecretsPanelViewModel
    let canvasSize: CGSize
    let isLocked: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown && viewModel.cardCount > 0 {
                panel
                if !isLocked {
                    movableBox
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .preference(key: InteractiveRegionPreferenceKey.self, value: interactiveRegions)
    }

    private var scale: CGFloat { CGFloat(viewModel.scaling) }
    private var width: CGFloat { SizeHelper.trackerWidth }
    private var originX: CGFloat { canvasSize.width * CGFloat(viewModel.left) / 100.0 }
    private var originY: CGFloat { canvasSize.height * CGFloat(viewModel.top) / 100.0 }

    /// SecretsHeight, the box the list has to fit into, in the panel's own units.
    private var boxHeight: CGFloat {
        max(canvasSize.height * CGFloat(viewModel.height) / 100.0 / max(scale, 0.01), 0)
    }

    /// The rows shrink to fit the box, as `CardListHelper.AutoScaleCardTiles` does
    /// for the deck stacks, but never grow past the chosen card size.
    private var cardHeight: CGFloat {
        let count = CGFloat(viewModel.cardCount)
        guard count > 0 else { return CGFloat(Settings.cardSize.rowHeight) }
        return min(CGFloat(Settings.cardSize.rowHeight), max(boxHeight / count, 0))
    }

    private var listHeight: CGFloat { cardHeight * CGFloat(viewModel.cardCount) }

    // Same rule as the deck stacks: the secret helper's own window was
    // click-through whenever the overlay was locked.
    private var interactiveRegions: [CGRect] {
        guard viewModel.isShown, viewModel.cardCount > 0, !isLocked, boxHeight > 0 else { return [] }
        return [CGRect(x: originX, y: originY, width: width * scale, height: boxHeight * scale)]
    }

    private var panel: some View {
        VStack(spacing: 0) {
            CardTileListView(cards: viewModel.cards.cards, playerType: .secrets,
                             cardHeight: cardHeight, reset: viewModel.cards.reset,
                             hoverKind: .secrets)
                .frame(width: width, height: listHeight)
        }
        .frame(width: width, height: boxHeight, alignment: .top)
        // As for the deck trackers: the backdrop the panel's own window used to
        // draw, now the panel's own background.
        .background(Color.black.opacity(Settings.trackerOpacity / 100.0))
        .scaleEffect(scale, anchor: .topLeading)
        .offset(x: originX, y: originY)
    }

    /// The drag and resize surface, in canvas pixels - see
    /// `TrackerPanelView.movableBox` for why it is a sibling rather than an
    /// overlay inside the scaled panel.
    private var movableBox: some View {
        let box = boxHeight * scale
        let boxWidth = width * scale
        return ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color(hex: "#4C0000FF"))
                .frame(width: boxWidth, height: box)
                .gesture(dragGesture)
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: TrackerPanelLayout.resizeGripSize,
                       height: TrackerPanelLayout.resizeGripSize)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { viewModel.resize(translation: $0.translation, canvasSize: canvasSize) }
                        .onEnded { _ in viewModel.endDrag() }
                )
        }
        .frame(width: boxWidth, height: box, alignment: .bottomTrailing)
        .offset(x: originX, y: originY)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard !isLocked else { return }
                viewModel.drag(translation: value.translation, canvasSize: canvasSize)
            }
            .onEnded { _ in viewModel.endDrag() }
    }

}
