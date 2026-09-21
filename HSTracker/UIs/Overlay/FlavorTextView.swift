//
//  FlavorTextView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's GridFlavorText, the parchment panel in the bottom-right corner that
// shows a hovered card's flavor text, plus the OverlayWindow properties behind
// it (FlavorText, FlavorTextCardName, FlavorTextVisibility) and its
// SetFlavorTextEntity. Replaces the 298x123 FlavorText NSPanel.
final class FlavorTextViewModel: ObservableObject {
    // FlavorTextVisibility.
    @Published var isShown = false
    // FlavorTextCardName and FlavorText.
    @Published var cardName = ""
    @Published var flavorText = ""

    // OverlayWindow.SetFlavorTextEntity. Note what it does *not* do: when the
    // setting is off, or the entity resolves to a card with no flavor text, it
    // returns without hiding the panel, so whatever was last shown stays up
    // until the cursor leaves the board. Carried over as-is.
    func setEntity(_ entity: Entity) {
        guard Settings.showFlavorText else { return }
        guard !(AppDelegate.instance().coreManager?.game.isBattlegroundsMatch() ?? false) else { return }
        let card = entity.info.latestCardId == entity.cardId
            ? entity.card
            : Cards.any(byId: entity.info.latestCardId)
        guard let card, !card.formattedFlavorText.isEmpty else { return }
        flavorText = card.formattedFlavorText
        cardName = card.name
        isShown = true
    }

    func hide() {
        isShown = false
    }
}

struct FlavorTextView: View {
    @ObservedObject var viewModel: FlavorTextViewModel
    // The overlay's real, post-scale size. The panel belongs in
    // RootOverlayView's fixed-pixel layer rather than its 1080-reference scaled
    // subtree: nothing in OverlayWindow ever gives GridFlavorText a
    // ScaleTransform, so HDT draws it at a flat 298x123 however large the
    // client is - which is what the AppKit panel's fixed frame did too.
    let canvasSize: CGSize

    // Width and Height on the Grid, and the 10 that
    // OverlayWindow.UpdateOverlay insets it from the bottom-right corner
    // (Canvas.Top = Height - ActualHeight - 10, Canvas.Left = Width - ... - 10).
    private static let panelSize = CGSize(width: 298, height: 123)
    private static let margin: CGFloat = 10

    // flavor_text.png is 298x118 and carries a 72-dpi pHYs chunk, so WPF
    // measures it at 397.33x157.33; the default Stretch="Uniform" then scales
    // it to fit the 298-wide Grid, which lands it back at its pixel size. It is
    // centred, so 2.5 of the Grid shows above and below it.
    private static let artSize = CGSize(width: 298, height: 118)

    // Width="200" VerticalAlignment="Top" on banner.png, which is 281x65 at the
    // same dpi - Uniform makes the element 200 wide and the aspect gives the
    // height. Horizontally it is WPF's default Stretch, which centres it here
    // because 200 is narrower than the Grid.
    private static let bannerWidth: CGFloat = 200
    private static let bannerHeight: CGFloat = 200 * 65 / 281

    // FontSize="14" and Margin="0,7,0,0" on the card name.
    private static let nameFontSize: CGFloat = 14
    private static let nameTopMargin: CGFloat = 7

    // Margin="20,45,20,20" on the flavor text, which is centred in what those
    // margins leave it. WPF's default TextBlock FontSize is 12.
    private static let textInsets = EdgeInsets(top: 45, leading: 20, bottom: 20, trailing: 20)
    private static let textFontSize: CGFloat = 12

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while hidden, which is what replaces
        // the window show/hide.
        ZStack(alignment: .bottomTrailing) {
            Color.clear
            if viewModel.isShown {
                panel.padding(Self.margin)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .bottomTrailing)
    }

    private var panel: some View {
        ZStack {
            Image("flavor_text")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.artSize.width, height: Self.artSize.height)

            VStack(spacing: 0) {
                Image("hs_banner")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.bannerWidth, height: Self.bannerHeight)
                Spacer(minLength: 0)
            }

            VStack(spacing: 0) {
                cardName.padding(.top, Self.nameTopMargin)
                Spacer(minLength: 0)
            }

            flavorText
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
    }

    // A HearthstoneTextBlock, so Chunkfive with OutlinedTextBlock's default
    // white fill over a black stroke. HDT overrides the family to
    // Card.DefaultFont, which drops to the system font in bold for the card
    // languages Chunkfive does not cover.
    private var cardName: some View {
        Text(verbatim: viewModel.cardName)
            .font(Settings.usesLatinCardFont
                  ? .custom("ChunkFive", size: Self.nameFontSize)
                  : .system(size: Self.nameFontSize, weight: .bold))
            .outlinedText()
            // OutlinedTextBlock.OnRender drops an unconstrained left-aligned
            // line by a twentieth of its own height before drawing it.
            .offset(y: Self.nameLineHeight * 0.05)
            .fixedSize()
    }

    private var flavorText: some View {
        OverlayFormattedText.text(viewModel.flavorText, size: Self.textFontSize, weight: .semibold)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: Self.panelSize.width - Self.textInsets.leading - Self.textInsets.trailing,
                   height: Self.panelSize.height - Self.textInsets.top - Self.textInsets.bottom)
            // The band the margins leave sits below the Grid's own centre, by
            // half the difference between the top and bottom margins.
            .offset(y: (Self.textInsets.top - Self.textInsets.bottom) / 2)
    }

    private static let nameLineHeight: CGFloat = {
        guard let font = NSFont(name: "ChunkFive", size: FlavorTextView.nameFontSize) else {
            return FlavorTextView.nameFontSize
        }
        return font.ascender - font.descender + font.leading
    }()
}
