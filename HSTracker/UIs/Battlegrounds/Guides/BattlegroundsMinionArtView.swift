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
// No premium/golden variant: a guide's minion is illustrative (drawn from
// the card definition alone), not a live board entity, so there's no
// concept of a golden copy to reflect. No tier badge either - HDT's overlay
// draws one (Image("tier-N")), but no tier-N asset exists in this catalog
// yet; add one and the badge below whenever it does.
@available(macOS 10.15, *)
struct BattlegroundsMinionArtView: View {
    let minion: BattlegroundsCompGuideViewModel.GuideMinion

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
                Image("taunt")
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

            Image("border")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.frameWidth, height: Self.frameHeight)
                .offset(x: Self.frameOffset.width, y: Self.frameOffset.height)

            if minion.hasReborn {
                overlayImage("reborn")
            }
            if minion.isLegendary {
                overlayImage("legendary")
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
            overlayImage("stats")
            if minion.hasDivineShield {
                overlayImage("divine-shield")
            }

            Text("\(minion.attack)")
                .font(.system(size: 45, weight: .bold))
                .outlinedText()
                .frame(width: 75, height: 75, alignment: .center)
                .offset(x: 29, y: 170)
            Text("\(minion.health)")
                .font(.system(size: 45, weight: .bold))
                .outlinedText()
                .frame(width: 75, height: 75, alignment: .center)
                .offset(x: 151, y: 170)

            if minion.tier > 0 {
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
        .cardImageTooltip(cardId: minion.card.id)
    }

    // Tier badge using the same tier-N.png assets that BattlegroundsTierOverlayView
    // already ships (Resources/Battlegrounds/tier-1.png … tier-7.png). The images
    // are 105×114 and include the number; no text overlay needed. The badge lives
    // inside the 256-pt reference canvas (which scaledToFrame shrinks to 70×70 at
    // the call site), so it is sized so it reads clearly after that 0.273× scale:
    // 80×87 → ≈22×24 pt on screen, roughly matching HDT's in-game badge size.
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
