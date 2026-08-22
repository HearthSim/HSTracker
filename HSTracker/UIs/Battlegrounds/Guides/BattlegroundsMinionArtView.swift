//
//  BattlegroundsMinionArtView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsMinion control: the full layered minion tile
// (card portrait clipped into the frame, keyword badges, attack/health)
// used throughout the Battlegrounds guides, not just a plain circular
// portrait (MulliganCardPortraitView is for Constructed's mulligan guide,
// which never needed the full BG frame treatment). Ported from the same
// recipe already shipping in the sibling Arenasmith app, substituted to load
// art via HSTracker's own ImageUtils instead of Arenasmith's
// CardAssetViewModel/AssetDownloader (this codebase doesn't have that
// system, and doesn't need it - ImageUtils.art/cachedArt already do the
// same job, matching GuideCardArtBackground/MulliganCardPortraitView).
//
// Driven by BattlegroundsMinionArt, which either derives its stats from a card
// definition (the comp guides, where a minion is illustrative) or carries them
// verbatim (the Inspiration panel, whose boards are real first-place lineups
// full of buffed and golden minions).
// Everything BattlegroundsMinionArtView needs to draw one minion. Two sources
// feed it: a card definition (comp guides - printed stats, keywords read off
// the card's mechanics) and an explicit set of values (the Inspiration panel,
// whose stats and keywords come off the wire).
//
// id is a UUID rather than the dbf id because a single board can hold several
// copies of the same minion, and ForEach needs them distinct.
@available(macOS 10.15, *)
struct BattlegroundsMinionArt: Identifiable {
    let id = UUID()
    let dbfId: Int
    let card: Card
    let isAvailable: Bool
    let attack: Int
    let health: Int
    let tier: Int
    let hasTaunt: Bool
    let hasReborn: Bool
    let hasDeathrattle: Bool
    let hasPoisonous: Bool
    let hasVenomous: Bool
    let hasDivineShield: Bool
    let isLegendary: Bool
    let isPremium: Bool
    // HDT's BattlegroundsMinionViewModel.HasTier, which only turns on once Tier
    // is assigned - the Inspiration panel never assigns it, so its boards carry
    // no tier badges.
    let showTier: Bool
    // HDT's ShowTripleTooltip, set false in the Inspiration panel: a premium
    // minion there is already the golden copy, so pairing the tooltip with
    // "and here is the golden version" would just repeat it.
    let showTriple: Bool
    // HDT's ToolTipService.Placement, which differs per panel: Left on
    // CompGuide.xaml's BattlegroundsMinion style, Right in
    // BattlegroundsInspiration.xaml (and by default everywhere else).
    let tooltipPlacement: CardTooltipPlacement

    // Comp guides: printed stats straight off the card definition.
    init(dbfId: Int, card: Card, isAvailable: Bool) {
        self.dbfId = dbfId
        self.card = card
        self.isAvailable = isAvailable
        self.attack = card.attack
        self.health = card.health
        self.tier = card.techLevel
        self.hasTaunt = card.mechanics.contains("TAUNT")
        self.hasReborn = card.mechanics.contains("REBORN")
        self.hasDeathrattle = card.mechanics.contains("DEATHRATTLE")
        self.hasPoisonous = card.mechanics.contains("POISONOUS")
        self.hasVenomous = card.mechanics.contains("VENOMOUS")
        self.hasDivineShield = card.mechanics.contains("DIVINE_SHIELD")
        self.isLegendary = card.rarity == .legendary
        self.isPremium = false
        self.showTier = true
        self.showTriple = true
        self.tooltipPlacement = .left
    }

    // Inspiration: a real board, so every stat and keyword is whatever the API
    // reported rather than what the card prints.
    init(card: Card, attack: Int, health: Int, isPremium: Bool, hasTaunt: Bool,
         hasReborn: Bool, hasDeathrattle: Bool, hasPoisonous: Bool,
         hasVenomous: Bool, hasDivineShield: Bool) {
        self.dbfId = card.dbfId
        self.card = card
        self.isAvailable = true
        self.attack = attack
        self.health = health
        self.tier = card.techLevel
        self.hasTaunt = hasTaunt
        self.hasReborn = hasReborn
        self.hasDeathrattle = hasDeathrattle
        self.hasPoisonous = hasPoisonous
        self.hasVenomous = hasVenomous
        self.hasDivineShield = hasDivineShield
        self.isLegendary = card.rarity == .legendary
        self.isPremium = isPremium
        self.showTier = false
        self.showTriple = false
        self.tooltipPlacement = .right
    }
}

@available(macOS 10.15, *)
struct BattlegroundsMinionArtView: View {
    let minion: BattlegroundsMinionArt

    @SwiftUI.State private var portrait: NSImage?
    @SwiftUI.State private var isHovering = false

    // HDT's card frame/overlay art (taunt, border, stats, etc.) is all
    // authored at 300x350; the portrait itself clips into a 256x256
    // reference canvas offset by (-24,-36) within that frame. Both extend
    // beyond the eventual on-screen tile size and get scaled down together
    // via .scaledToFrame, matching Arenasmith's approach - the alternative
    // (hand-tuning every offset for a smaller target size) risks the pieces
    // drifting out of alignment with each other.
    private static let frameWidth: CGFloat = 300
    private static let frameHeight: CGFloat = 350
    private static let frameOffset = CGSize(width: -24, height: -36)
    private static let portraitSize: CGFloat = 256

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: Self.portraitSize, height: Self.portraitSize)

            if minion.hasTaunt {
                Image(minion.isPremium ? "taunt_premium" : "taunt")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: Self.frameWidth, height: Self.frameHeight)
                    .offset(x: Self.frameOffset.width, y: Self.frameOffset.height)
            }

            if let portrait {
                Image(nsImage: portrait)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Self.portraitSize, height: Self.portraitSize)
                    .clipShape(Ellipse().path(in: CGRect(x: 128 - 87, y: 128 - 120, width: 174, height: 240)))
            }

            Image(minion.isPremium ? "border_premium" : "border")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.frameWidth, height: Self.frameHeight)
                .offset(x: Self.frameOffset.width, y: Self.frameOffset.height)

            if minion.hasReborn {
                overlayImage("reborn")
            }
            if minion.isLegendary {
                overlayImage(minion.isPremium ? "legendary_premium" : "legendary")
            }
            if minion.hasDeathrattle {
                overlayImage("deathrattle")
            }
            if minion.hasPoisonous {
                overlayImage("poisonous")
            }
            if minion.hasVenomous {
                overlayImage("venomous")
            }
            overlayImage(minion.isPremium ? "stats_premium" : "stats")
            if minion.hasDivineShield {
                overlayImage("divine-shield")
            }

            statNumber(minion.attack).offset(x: 29, y: 170)
            statNumber(minion.health).offset(x: 151, y: 170)

            if minion.showTier && minion.tier > 0 {
                tierBadge
            }
        }
        .frame(width: Self.portraitSize, height: Self.portraitSize)
        .opacity(minion.isAvailable ? 1.0 : 0.5)
        .onAppear(perform: loadPortrait)
        // Matches CompGuide.xaml's BattlegroundsMinion style: RenderTransform
        // ScaleTransform to 1.05 on IsMouseOver (default anchor is center in
        // both WPF and SwiftUI, so no explicit anchor needed), plus the
        // ToolTipService.Placement="Left"/CardTooltip binding. Uses
        // .trackHover rather than .onHover - see HoverTrackingNSView in
        // CardImageTooltip.swift.
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .trackHover { hovering in isHovering = hovering }
        .cardImageTooltip(cardId: minion.card.id, showTriple: minion.showTriple,
                          placement: minion.tooltipPlacement)
    }

    // Tier badge using the tier-N.png assets in
    // Resources/Battlegrounds (tier-1.png … tier-7.png). The images
    // are 105×114 and include the number; no text overlay needed. The badge lives
    // inside the 256-pt reference canvas (which scaledToFrame shrinks to 70×70 at
    // the call site), so it is sized so it reads clearly after that 0.273× scale:
    // 80×87 → ≈22×24 pt on screen, roughly matching HDT's in-game badge size.
    // HearthstoneTextBlock Text="{Binding Attack}" Width="75" Height="75"
    // FontSize="45" FontWeight="Bold" TextAlignment="Center", at Canvas.Left
    // 29 / 151 and Canvas.Top 170.
    //
    // Two things the obvious SwiftUI spelling gets wrong here, both of which a
    // late-game Battlegrounds board makes visible:
    //
    //  - Text(verbatim:), not Text("\(value)"). The interpolating form resolves
    //    to LocalizedStringKey, and its Int interpolation runs the value through
    //    the locale's number format - so a 4096-attack minion rendered "4,096"
    //    in en_US. WPF's {Binding} just calls ToString(), with no separator.
    //  - the text must *shrink* to fit the 75pt box, not truncate. SwiftUI's
    //    Text ellipsizes by default, so a buffed stat rendered "4,...". The
    //    shrink is not in HDT's XAML - it is in OutlinedTextBlock.MeasureOverride,
    //    which walks the font size down from the declared FontSize one point at
    //    a time until the formatted text fits availableSize in both axes (down
    //    to 1pt). At 45pt bold even three digits exceed 75pt, so most late-game
    //    stats are drawn below their nominal size in HDT too.
    //
    // minimumScaleFactor scales continuously rather than in whole points, which
    // is the one difference from HDT's loop; the floor matches its `fontSize > 1`
    // termination, so like HDT this never has to fall back to truncating.
    private func statNumber(_ value: Int) -> some View {
        Text(verbatim: "\(value)")
            .font(.system(size: 45, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(1.0 / 45.0)
            .outlinedText()
            .frame(width: 75, height: 75, alignment: .center)
    }

    private var tierBadge: some View {
        Group {
            if let image = Self.tierImage(minion.tier) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 87)
                    .offset(x: 175, y: 3)
            }
        }
    }

    private static func tierImage(_ tier: Int) -> NSImage? {
        guard tier > 0, let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-\(tier).png")
    }

    private func overlayImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .frame(width: Self.frameWidth, height: Self.frameHeight)
            .offset(x: Self.frameOffset.width, y: Self.frameOffset.height)
    }

    private func loadPortrait() {
        if let cached = ImageUtils.cachedArt(cardId: minion.card.id) {
            portrait = cached
            return
        }
        ImageUtils.art(for: minion.card.id) { img in
            DispatchQueue.main.async {
                self.portrait = img
            }
        }
    }
}

@available(macOS 10.15, *)
extension View {
    // Resizes a view authored at baseWidth (a square reference canvas) down
    // to a target tile size via scaleEffect rather than re-deriving every
    // internal offset for each size the tile is used at.
    func scaledToFrame(width: CGFloat, height: CGFloat, baseWidth: CGFloat = 256) -> some View {
        let scale = width / baseWidth
        return self
            .frame(width: baseWidth, height: baseWidth)
            .scaleEffect(scale, anchor: UnitPoint(x: 0.535, y: 0.55))
            .frame(width: width, height: height)
    }
}
