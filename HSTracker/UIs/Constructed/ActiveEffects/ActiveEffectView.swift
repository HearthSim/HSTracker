//
//  ActiveEffectView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// SwiftUI replacement for the old ActiveEffect.xib (an AppKit NSView: two
// nested NSBox borders around a zoomed card-art crop, with a count badge in
// the corner). Geometry below - the 61pt cell, the 49/43/37 nesting, the
// 3pt borders, the 8/5 corner radii, the art's 55pt frame at (-10, -7), the
// 24pt badge - is ported verbatim from that xib rather than redesigned, so
// the tile looks identical.
@available(macOS 10.15, *)
final class ActiveEffectViewModel: ObservableObject, Identifiable {
    let effect: EntityBasedEffect
    // HDT's ActiveEffect.Count: nil unless the effect both wants a count shown
    // and has more than one copy in play.
    let count: Int?

    let id = UUID()

    @Published private(set) var cardImage: NSImage?

    init(effect: EntityBasedEffect, count: Int? = nil) {
        self.effect = effect
        self.count = count
        loadImage()
    }

    private func loadImage() {
        guard let cardId = effect.cardIdToShowInUI else { return }
        ImageUtils.art(for: cardId) { [weak self] image in
            DispatchQueue.main.async { self?.cardImage = image }
        }
    }

    // The two border colours the xib set in ActiveEffect.commonInit().
    var outerBorderColor: Color {
        Color(hex: effect.isControlledByPlayer ? "#29293d" : "#e39d91")
    }

    var innerBorderColor: Color {
        Color(hex: effect.isControlledByPlayer ? "#8c7ca3" : "#671e14")
    }
}

@available(macOS 10.15, *)
struct ActiveEffectView: View {
    @ObservedObject var viewModel: ActiveEffectViewModel

    // HDT's ActiveEffectsOverlay.EffectSize (49) and InnerMargin (6): the cell
    // is the tile plus a margin on each side.
    static let effectSize: CGFloat = 49
    static let innerMargin: CGFloat = 6
    static let cellSize: CGFloat = effectSize + innerMargin * 2

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            tile
                .frame(width: Self.effectSize, height: Self.effectSize)
                .padding(Self.innerMargin)
            if viewModel.count != nil {
                countBadge
            }
        }
        .frame(width: Self.cellSize, height: Self.cellSize)
        // HDT marks the tile IsOverlayHoverVisible with a CardTooltip, which
        // is what this modifier is - the cursor is matched against the shared
        // registry rather than by an NSTrackingArea, because the canvas stays
        // click-through and a click-through window is delivered no
        // mouse-entered events at all.
        .cardImageTooltip(cardId: viewModel.effect.cardToShowInUI?.id)
    }

    // The xib's OuterBorder box (49x49, 3pt border, radius 8) wrapping the
    // InnerBorder box (43x43, 3pt border, radius 5) wrapping the 37x37 art.
    private var tile: some View {
        // strokeBorder, not stroke: NSBox draws its borderWidth inside its own
        // bounds, so the 43pt inner box and the 49pt outer box each keep their
        // stated size. A centred stroke would straddle the edge and push the
        // outer border 1.5pt past the 49pt tile.
        art
            .frame(width: 37, height: 37)
            .padding(3)
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(viewModel.innerBorderColor, lineWidth: 3))
            .padding(3)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(viewModel.outerBorderColor, lineWidth: 3))
    }

    // The xib's image view: 55x55, its top-left corner 10pt left of and 7pt
    // above the 37x37 window it is cropped to. As in CounterChipView, the
    // image has to be anchored .topLeading before the offset is applied - a
    // ZStack would centre it first and crop a different region of the art.
    private var art: some View {
        Group {
            if let cardImage = viewModel.cardImage {
                Image(nsImage: cardImage).resizable().aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .frame(width: 55, height: 55)
        .offset(x: -10, y: -7)
        .frame(width: 37, height: 37, alignment: .topLeading)
        .clipped()
    }

    // The xib's Count view: a 24pt circle sitting in the cell's bottom-right
    // corner so it overhangs the outer border. Its NSBox gave border and fill
    // the same systemGray, so the 3pt border is not drawn separately here - it
    // would only repaint the disc's own rim in its own colour.
    private var countBadge: some View {
        Text(verbatim: viewModel.count.map { "\($0)" } ?? "")
            .chunkFive(size: 16)
            .foregroundColor(.white)
            .fixedSize()
            .frame(width: 24, height: 24)
            .background(Circle().fill(Color(NSColor.systemGray)))
    }
}
