//
//  CardTileView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// One row of a deck list - HDT's `Controls/CardTile.xaml`, and the SwiftUI
/// replacement for `CardBar` inside the overlay.
///
/// `CardBar` composes the theme's PNGs and its text into a `CALayer` at rects
/// authored against a 217x34 box, dividing every one of them by the card size's
/// ratio as it draws. This composes the same PNGs at the same rects and applies
/// that size once, as a scale on the finished row - so the layer order, the
/// offsets and the conditions below are `CardBar.draw`'s, carried over as they
/// are, and `CardTileTheme` holds what the four bar subclasses varied.
///
/// `CardBar` itself stays: the deck manager, `EditDeck` and the Outfinder pool
/// browser are outside the overlay and still use it.
@available(macOS 10.15, *)
struct CardTileView: View {
    let card: Card?
    let playerType: PlayerType
    var playerName: String?
    /// The row's on-screen height; the 34-high authored box scales to it.
    let rowHeight: CGFloat
    /// Non-zero when this row's count just changed, and distinct from the last
    /// time it did - which is what makes the flash re-trigger rather than stay put.
    var flashToken: Int = 0

    /// The shared tile cache, observed so a row redraws when its art arrives.
    @ObservedObject private var artCache = CardTileArtCache.shared

    private var theme: CardTileTheme { CardTileTheme.current }

    private var art: NSImage? {
        guard let card else { return nil }
        return theme.usesBlurredFullWidthArt
            ? artCache.smallArt(for: card.id)
            : artCache.tile(for: card.id)
    }
    private var scale: CGFloat { rowHeight / CardTileTheme.frameRect.height }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            content
        }
        .frame(width: CardTileTheme.frameRect.width, height: CardTileTheme.frameRect.height,
               alignment: .topLeading)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: CardTileTheme.frameRect.width * scale, height: rowHeight, alignment: .topLeading)
        .clipped()
    }

    @ViewBuilder
    private var content: some View {
        cardArt
        fadeOverlay
        if let card {
            if showsCountBox(card) {
                if theme.drawsCountBox {
                    themeImage(countBoxFilename(card), rect: CardTileTheme.boxRect)
                }
                countText(card)
            }
            if card.isCreated {
                createdIcon(card)
            }
            // Not the inverse of the count box: a single legendary shows the box
            // (without a number in it) *and* the star.
            if abs(card.count) <= 1 && rarity(of: card) == .legendary {
                themeImage("icon_legendary.png",
                           rect: CardTileTheme.boxRect.offsetBy(dx: theme.legendaryIconOffsetX, dy: 0))
            }
        }
        themeImage(frameFilename, rect: CardTileTheme.frameRect)
        if card != nil {
            gem
            costText
        }
        if let highlight = highlightFilename {
            themeImage(highlight, rect: CardTileTheme.frameRect)
        }
        cardName
        if card?.isBadAsMultiple == true {
            themeImage("icon_bad_multiple.png", rect: CardTileTheme.badAsMultipleRect)
        }
        if showsDarkening {
            themeImage("dark.png", rect: CardTileTheme.frameRect)
        }
        if card?.cardWinRates != nil {
            mulliganWinRate
        }
        flash
    }

    /// `CardBar.update(highlight:)`: the theme's frame mask filled with the
    /// theme's flash colour, fading 0.7 -> 0 over half a second.
    @ViewBuilder
    private var flash: some View {
        if flashToken != 0 && Settings.flashOnDraw {
            CardTileFlashView(color: theme.flashColor, mask: theme.image("frame_mask.png"))
                .place(CardTileTheme.frameRect)
                .id(flashToken)
        }
    }

    // MARK: - Layers

    private var cardArt: some View {
        Group {
            if let art {
                if theme.usesBlurredFullWidthArt {
                    // MinimalBar blurs the small art across the whole row rather
                    // than cropping a tile out of it.
                    Image(nsImage: art)
                        .resizable()
                        .blur(radius: 1.5)
                        .place(CardTileTheme.frameRect)
                } else {
                    Image(nsImage: art)
                        .resizable()
                        .place(artRect)
                }
            }
        }
    }

    private var artRect: CGRect {
        guard let card, theme.imageOffsetByCountBox else { return theme.imageRect }
        var count = card.count
        if count == 0 { count = 1 }
        return abs(count) > 1 || rarity(of: card) == .legendary
            ? theme.imageRect.offsetBy(dx: theme.imageOffset, dy: 0)
            : theme.imageRect
    }

    private var fadeOverlay: some View {
        Group {
            if card != nil {
                themeImage("fade.png", rect: fadeRect)
            }
        }
    }

    private var fadeRect: CGRect {
        guard let card, theme.fadeOffsetByCountBox else { return theme.fadeRect }
        return abs(card.count) > 1 || rarity(of: card) == .legendary
            ? theme.fadeRect.offsetBy(dx: theme.fadeOffset, dy: 0)
            : theme.fadeRect
    }

    private func createdIcon(_ card: Card) -> some View {
        let slides = abs(card.count) > 1 || rarity(of: card) == .legendary
        return themeImage("icon_created.png",
                          rect: slides
                          ? CardTileTheme.boxRect.offsetBy(dx: theme.createdIconOffset, dy: 0)
                          : CardTileTheme.boxRect)
    }

    private var gem: some View {
        Group {
            if let card, card.cost >= 0,
               !(Cards.isHero(cardId: card.id) && !Cards.isPlayableHero(cardId: card.id)) {
                themeImage(gemFilename(card), rect: CardTileTheme.gemRect)
            }
        }
    }

    // MARK: - Text

    private func countText(_ card: Card) -> some View {
        let count = abs(card.count)
        return Group {
            if count > 1 {
                Text(verbatim: "\(count)")
                    .font(CardTileTheme.font(CardTileTheme.numbersFontName, size: fittedCountSize(count)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    // Sized before the outline, not after: outlinedText stacks 9
                    // copies of its content, so a frame applied outside it
                    // constrains the stack and leaves each copy to lay out at its
                    // ideal width - which clips the glyphs instead of shrinking
                    // them, where CardBar's fitFontForSize shrinks.
                    .frame(width: CardTileTheme.boxRect.width, alignment: .center)
                    .outlinedText(countColor(card), width: CardTileTheme.outlineWidth)
                    .placeText(x: CardTileTheme.boxRect.minX + theme.countTextOffsetX,
                               baseline: CardTileTheme.baselineY(for: CardTileTheme.countTextRect),
                               ascent: CardTileTheme.ascent(CardTileTheme.numbersFontName,
                                                            size: fittedCountSize(count)))
            }
        }
    }

    private var costText: some View {
        Group {
            if let card, let cost = displayedCost(card) {
                Text(verbatim: "\(cost)")
                    .font(CardTileTheme.font(CardTileTheme.numbersFontName, size: CardTileTheme.costFontSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .frame(width: CardTileTheme.gemRect.width, alignment: .center)
                    .outlinedText(costColor(card), width: CardTileTheme.outlineWidth)
                    .placeText(x: CardTileTheme.gemRect.minX + theme.costOffsetX,
                               baseline: CardTileTheme.baselineY(for: CardTileTheme.costTextRect),
                               ascent: CardTileTheme.ascent(CardTileTheme.numbersFontName,
                                                            size: CardTileTheme.costFontSize))
            }
        }
    }

    private var cardName: some View {
        Group {
            if let name = displayedName {
                Text(verbatim: name)
                    .font(CardTileTheme.font(theme.nameFontName, size: fittedNameSize(name)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
                    .frame(width: nameRect.width, alignment: .leading)
                    .outlinedText(nameColor, width: CardTileTheme.outlineWidth)
                    .placeText(x: nameRect.minX,
                               baseline: CardTileTheme.baselineY(for: nameRect),
                               ascent: CardTileTheme.ascent(theme.nameFontName,
                                                            size: fittedNameSize(name)))
            }
        }
    }

    private var mulliganWinRate: some View {
        Group {
            if let card {
                themeImage(card.isMulliganOption ? "keeprate_active_box.png" : "keeprate_box.png",
                           rect: CardTileTheme.mulliganWinrateBoxRect)
                if let winrate = card.cardWinRates?.mulliganWinRate {
                    let delta = winrate - (card.cardWinRates?.baseWinrate ?? 50.0)
                    let color = Color(NSColor.fromHexString(hex: Helper.getColorString(delta: delta, intensity: 75)) ?? .white)
                    Text(verbatim: String(format: "%.1f%%", winrate))
                        .font(CardTileTheme.font(theme.nameFontName, size: CardTileTheme.mulliganWinRateFontSize))
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .frame(width: CardTileTheme.mulliganWinrateBoxRect.width, alignment: .center)
                        .outlinedText(color, width: CardTileTheme.outlineWidth)
                        .placeText(x: CardTileTheme.mulliganWinrateBoxRect.minX,
                                   baseline: CardTileTheme.baselineY(
                                    for: CardTileTheme.mulliganWinrateBoxRect.offsetBy(dx: 0, dy: 8)),
                                   ascent: CardTileTheme.ascent(theme.nameFontName,
                                                               size: CardTileTheme.mulliganWinRateFontSize))
                }
            }
        }
    }

    // MARK: - Values

    private func fittedNameSize(_ name: String) -> CGFloat {
        CardTileTheme.fittedFontSize(name, fontName: theme.nameFontName,
                                     box: nameRect.size, maxSize: CardTileTheme.nameFontSize)
    }

    /// `CardBar.addCountText` fits the count too, against the count text box and
    /// with the *name* font rather than the numbers one - which is what decides
    /// the size, even though the glyphs are then drawn in ChunkFive.
    private func fittedCountSize(_ count: Int) -> CGFloat {
        CardTileTheme.fittedFontSize("\(count)", fontName: theme.nameFontName,
                                     box: CardTileTheme.countTextRect.size,
                                     maxSize: CardTileTheme.countFontSize)
    }

    private func rarity(of card: Card) -> Rarity {
        card.rarity == .invalid && card.mechanics.contains("ELITE") ? .legendary : card.rarity
    }

    private func showsCountBox(_ card: Card) -> Bool {
        abs(card.count) > 1 || rarity(of: card) == .legendary
    }

    private var showsDarkening: Bool {
        guard let card, playerType != .hero,
              playerType != .cardList, playerType != .editDeck else {
            return false
        }
        return card.count <= 0 || card.jousted
    }

    private var displayedName: String? {
        if let playerName { return playerName }
        guard let card else { return nil }
        if let suffix = card.extraInfo?.cardNameSuffix {
            return "\(card.name) \(suffix)"
        }
        return card.name
    }

    private var nameColor: Color {
        if playerType == .cardList || playerType == .editDeck { return .white }
        guard playerName == nil, let card else { return .white }
        return Color(card.textColor())
    }

    private func costColor(_ card: Card) -> Color {
        if playerType == .cardList || playerType == .editDeck { return .white }
        if Cards.isHero(cardId: card.id) && !Cards.isPlayableHero(cardId: card.id) { return .white }
        return Color(card.textColor())
    }

    private func displayedCost(_ card: Card) -> Int? {
        if Cards.isHero(cardId: card.id) && !Cards.isPlayableHero(cardId: card.id) {
            return nil
        }
        return card.cost >= 0 ? card.cost : nil
    }

    private func countColor(_ card: Card) -> Color {
        guard theme.countColorFollowsRarity else { return CardTileTheme.countTextColor }
        switch card.rarity {
        case .rare: return Color(red: 0.1922, green: 0.5255, blue: 0.8706)
        case .epic: return Color(red: 0.6784, green: 0.4431, blue: 0.9686)
        case .legendary: return Color(red: 1.0, green: 0.6039, blue: 0.0627)
        default: return .white
        }
    }

    /// `CardBar.addCardName`'s width, which shrinks around whatever else the row
    /// is showing.
    private var nameRect: CGRect {
        if let fixed = theme.fixedCardNameRect { return fixed }
        let keepWidth: CGFloat = card?.cardWinRates != nil ? CardTileTheme.mulliganWinrateBoxRect.width : 0
        var width = CardTileTheme.frameRect.width - keepWidth - 38
        if let card {
            if abs(card.count) > 0 || rarity(of: card) == .legendary {
                width -= CardTileTheme.boxRect.width
            }
            if card.isCreated {
                width -= abs(theme.createdIconOffset)
            }
        }
        return CGRect(x: 38, y: 10, width: max(width, 1), height: 30)
    }

    private var frameFilename: String {
        guard Settings.showRarityColors, theme.hasRarityVariants("frame"), let card else {
            return "frame.png"
        }
        return "frame_\(rarityFilenameComponent(rarity(of: card))).png"
    }

    private func gemFilename(_ card: Card) -> String {
        guard Settings.showRarityColors, theme.hasRarityVariants("gem") else { return "gem.png" }
        return "gem_\(rarityFilenameComponent(rarity(of: card))).png"
    }

    private func countBoxFilename(_ card: Card) -> String {
        guard Settings.showRarityColors, theme.hasRarityVariants("countbox") else { return "countbox.png" }
        return "countbox_\(rarityFilenameComponent(rarity(of: card))).png"
    }

    private func rarityFilenameComponent(_ rarity: Rarity) -> String {
        switch rarity {
        case .rare: return "rare"
        case .epic: return "epic"
        case .legendary: return "legendary"
        default: return "common"
        }
    }

    private var highlightFilename: String? {
        switch card?.highlightColor {
        case .green: return "highlight_green.png"
        case .teal: return "highlight_teal.png"
        case .orange: return "highlight_orange.png"
        default: return nil
        }
    }

    @ViewBuilder
    private func themeImage(_ filename: String, rect: CGRect) -> some View {
        if let image = theme.image(filename) {
            Image(nsImage: image)
                .resizable()
                .place(rect)
        }
    }

}

@available(macOS 10.15, *)
private extension View {
    /// Places a layer at a rect authored in `CardBar`'s coordinates - a 217x34 box
    /// with a bottom-left origin - inside this view's top-left one.
    func place(_ rect: CGRect) -> some View {
        self.frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: CardTileTheme.frameRect.height - rect.maxY)
    }

    /// Places a text layer so its first baseline lands where `CardBar` puts it -
    /// see `CardTileTheme.baselineY`.
    func placeText(x: CGFloat, baseline: CGFloat, ascent: CGFloat) -> some View {
        self.fixedSize()
            .offset(x: x, y: baseline - ascent)
    }
}

/// The card art behind the rows, and a republish when a fetch lands.
///
/// `CardBar` could keep the image on itself and call `needsDisplay` when it
/// arrived. A SwiftUI row is a value with no identity of its own to hang that on
/// - and `.onChange`, the obvious way to notice the card under a reused row
/// changing, needs macOS 11 while this file's baseline is 10.15 - so the cache
/// owns both the images and the signal.
@available(macOS 10.15, *)
final class CardTileArtCache: ObservableObject {
    static let shared = CardTileArtCache()

    /// Bumped whenever a fetch lands, which is what redraws the rows waiting on it.
    @Published private var generation = 0

    private var requested = Set<String>()
    private var smallArt = [String: NSImage?]()

    /// The tile crop, kicking off a fetch the first time one is asked for.
    func tile(for cardId: String) -> NSImage? {
        if let cached = ImageUtils.cachedTile(cardId: cardId) {
            return cached
        }
        guard !requested.contains(cardId) else { return nil }
        requested.insert(cardId)
        // Off the current render pass: this is called from body.
        DispatchQueue.main.async { [weak self] in
            ImageUtils.tile(for: cardId) { image in
                guard image != nil else { return }
                DispatchQueue.main.async {
                    self?.generation += 1
                }
            }
        }
        return nil
    }

    /// The bundled small art, which is what the minimal theme blurs across the row.
    func smallArt(for cardId: String) -> NSImage? {
        if let cached = smallArt[cardId] { return cached }
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let image = NSImage(contentsOfFile: "\(resourcePath)/Resources/Small/\(cardId).png")
        smallArt[cardId] = image
        return image
    }
}

/// The flash itself, split out so its fade runs from `onAppear` - the view is
/// rebuilt (by `.id`) each time a row's count changes, which is what restarts it.
@available(macOS 10.15, *)
private struct CardTileFlashView: View {
    let color: Color
    let mask: NSImage?

    @SwiftUI.State private var opacity: Double = 0.7

    var body: some View {
        Group {
            if let mask {
                color.mask(Image(nsImage: mask).resizable())
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { opacity = 0 }
        }
    }
}
