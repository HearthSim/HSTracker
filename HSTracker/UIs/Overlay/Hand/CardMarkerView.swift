//
//  CardMarkerView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's CardMarker.xaml: a 36x36 age badge with the source-card tile hanging
// under it. Transcribed from the XAML rather than from the Core Graphics the
// AppKit CardHud drew, which had drifted - it drew the source tile inside the
// badge instead of below it, cropped a 34x55 slice of the tile where HDT takes
// a 59x59 square, and set the age in Belwe rather than HDT's Chunkfive.
@available(macOS 10.15, *)
struct CardMarkerView: View {
    @ObservedObject var viewModel: CardMarkerViewModel

    // Width/Height on the age Grid, and the card-marker art centred in it.
    static let badgeSide: CGFloat = 36
    private static let markerArtSide: CGFloat = 32

    // FontSize on the two HearthstoneTextBlocks.
    private static let ageFontSize: CGFloat = 18
    private static let costReductionFontSize: CGFloat = 13

    // Width/Height of the icon, and of the cost reduction block.
    private static let iconSide: CGFloat = 16

    // The source tile badge: Border Margin="4,-2,4,0" BorderThickness="2"
    // CornerRadius="3" BorderBrush="#141617" Width="24" Height="24".
    private static let sourceBadgeSide: CGFloat = 24
    private static let sourceBorderThickness: CGFloat = 2
    private static let sourceBadgeTopMargin: CGFloat = -2
    private static let sourceTileSide: CGFloat = 20
    private static let sourceBorderColor = Color(hex: "#141617")

    // ToolTipService.VerticalOffset on the UserControl.
    private static let tooltipVerticalOffset: CGFloat = 20

    var body: some View {
        // The StackPanel: the age badge, then the source tile under it. A
        // collapsed age badge takes the tile up with it.
        VStack(spacing: 0) {
            if viewModel.cardAge != nil {
                ageBadge
            }
            if viewModel.sourceCard != nil {
                sourceBadge
                    .padding(.top, Self.sourceBadgeTopMargin)
            }
        }
        .frame(width: Self.badgeSide, alignment: .top)
        .opacity(viewModel.isShown ? 1 : 0)
        // ext:OverlayExtensions.ToolTip="{x:Type tooltips:CardTooltip}" with
        // IsOverlayHoverVisible, both on the UserControl itself: hovering a
        // marker shows the card its source tile came from, captioned with how
        // the card got there. ToolTipService.Placement="Bottom" and
        // VerticalOffset="20" put it under the marker rather than beside it,
        // which is what keeps it clear of the opponent's hand.
        //
        // Attached here rather than by the parent because the card and the
        // caption both come off this view model - a parent that does not
        // observe it would go on handing the tooltip the previous card.
        //
        // Dropped along with the marker itself while it is hidden: HDT collapses
        // the control, and a collapsed WPF element is not hit-testable, so it
        // raises no hover either.
        .cardImageTooltip(cardId: viewModel.isShown ? viewModel.sourceCard?.id : nil,
                          showTriple: false, text: viewModel.tooltipText,
                          placement: .bottom, verticalOffset: Self.tooltipVerticalOffset)
    }

    private var ageBadge: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: Self.badgeSide, height: Self.badgeSide)

            Image("card-marker")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.markerArtSide, height: Self.markerArtSide)
                .offset(x: (Self.badgeSide - Self.markerArtSide) / 2,
                        y: (Self.badgeSide - Self.markerArtSide) / 2)

            if let cardAge = viewModel.cardAge {
                // Width="32" Height="32" TextAlignment="Center", which is the
                // branch of OutlinedTextBlock.OnRender that centres the line in
                // the block's own height before dropping it a twentieth of one.
                Text(verbatim: "\(cardAge)")
                    .chunkFive(size: Self.ageFontSize)
                    .outlinedText()
                    .fixedSize()
                    .frame(width: Self.markerArtSide, height: Self.markerArtSide)
                    .offset(x: (Self.badgeSide - Self.markerArtSide) / 2,
                            y: (Self.badgeSide - Self.markerArtSide) / 2
                                + Self.lineHeight(Self.ageFontSize) * 0.05)
            }

            if let icon = viewModel.icon {
                // Margin="18,18,-2,-2" on a 16pt icon leaves it a 20pt slot, so
                // WPF's centring puts it 2 further in again - the bottom-right
                // corner of the badge.
                Image(icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.iconSide, height: Self.iconSide)
                    .offset(x: 20, y: 20)
            }

            if let costReduction = viewModel.costReduction {
                Text(verbatim: "\(costReduction)")
                    .chunkFive(size: Self.costReductionFontSize)
                    .outlinedText(Color(red: 0.117, green: 0.565, blue: 1))
                    .fixedSize()
                    .frame(width: Self.iconSide, height: Self.iconSide)
                    .offset(x: Self.badgeSide - Self.iconSide,
                            y: Self.lineHeight(Self.costReductionFontSize) * 0.05)
            }
        }
        .frame(width: Self.badgeSide, height: Self.badgeSide, alignment: .topLeading)
    }

    private var sourceBadge: some View {
        ZStack(alignment: .topLeading) {
            CardMarkerSourceTile(card: viewModel.sourceCard)
                // A fresh identity per card, so the tile reloads when the
                // source changes - .onAppear only runs once per identity.
                .id(viewModel.sourceCard?.id)
                .frame(width: Self.sourceTileSide, height: Self.sourceTileSide)

            if let icon = viewModel.icon {
                // Margin="-8" with Left/Top alignment, measured from the
                // Border's content area - so the icon straddles its corner.
                Image(icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.iconSide, height: Self.iconSide)
                    .offset(x: -8, y: -8)
            }
        }
        .frame(width: Self.sourceTileSide, height: Self.sourceTileSide, alignment: .topLeading)
        .padding(Self.sourceBorderThickness)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Self.sourceBorderColor, lineWidth: Self.sourceBorderThickness)
        )
    }

    private static func lineHeight(_ size: CGFloat) -> CGFloat {
        guard let font = NSFont(name: "ChunkFive", size: size) else { return size }
        return font.ascender - font.descender + font.leading
    }
}

// The square crop of the source card's tile that HDT shows in the badge:
// CropRect = { X = 126, Y = 0, Width = 59, Height = 59 } over the 256x59 tile.
@available(macOS 10.15, *)
private struct CardMarkerSourceTile: View {
    let card: Card?

    @SwiftUI.State private var image: NSImage?

    private static let crop = NSRect(x: 126, y: 0, width: 59, height: 59)

    var body: some View {
        // Color.clear rather than a bare `if`: .onAppear does not fire on a view
        // that renders empty, and until the tile arrives that is what this is.
        ZStack {
            Color.clear
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
            }
        }
        .clipped()
        .onAppear(perform: load)
    }

    private func load() {
        guard let card else { return }
        if let cached = ImageUtils.cachedTile(cardId: card.id) {
            image = cached.crop(rect: Self.crop)
            return
        }
        ImageUtils.tile(for: card.id) { img in
            DispatchQueue.main.async {
                self.image = img?.crop(rect: Self.crop)
            }
        }
    }
}
