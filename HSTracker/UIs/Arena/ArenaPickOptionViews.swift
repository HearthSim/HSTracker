//
//  ArenaPickOptionViews.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// A badge pinned under one of the three offered cards.
///
/// HDT builds these from a `Border` with `BorderThickness="2,0,2,2"` and a
/// `CornerRadius="0,0,3,3"` - a tab that reads as hanging off the bottom edge of
/// the card - with the icon clipped inside it.
@available(macOS 10.15, *)
private struct ArenaOptionBadge<Content: View>: View {
    let foreground: Color
    /// HDT's `BadgeBorderColor` - teal normally, red in Underground, and white on
    /// the improvements badge while it is highlighted.
    let border: Color
    let isUnderground: Bool
    /// See `ArenaBadgeTexture`.
    let textureSize: CGSize
    let dimmed: Bool
    @ViewBuilder let content: () -> Content

    private var shape: UnevenRoundedCornersShape {
        UnevenRoundedCornersShape(bottomLeading: 3, bottomTrailing: 3)
    }

    /// HDT's badge is a 26-tall grid with a 28pt minimum width, and the content
    /// sits inside the border's `Padding="4,0"` - so the inset is applied before
    /// the minimum, not after it.
    var body: some View {
        content()
            .foregroundColor(foreground)
            .padding(.horizontal, 4)
            .frame(minWidth: 28)
            .frame(height: 26)
            .background(background)
            .opacity(dimmed ? 0.2 : 1)
            // DropShadowEffect BlurRadius="5" ShadowDepth="2" Direction="-115",
            // which points down and to the left.
            .shadow(color: .black.opacity(0.2), radius: 2.5, x: -0.85, y: 1.81)
    }

    /// Five layers, as the XAML stacks them: a black base, the arena_cell_bg
    /// texture masked to it, a translucent black inner edge, the coloured border
    /// over a barely-there dark wash, and a shade falling from the top edge.
    /// The borders are open on top - XAML's `BorderThickness="2,0,2,2"` - so they
    /// read as the badge hanging off the plate above it.
    private var background: some View {
        ZStack {
            // Only this subtree is clipped: the strokes below sit on the boundary
            // and would lose their outer half to a clip applied over everything.
            shape.fill(Color.black)
                .overlay(texture)
                .clipShape(shape)
            ArenaBadgeSideBorder()
                .stroke(Color.black.opacity(0.267), lineWidth: 3)
                .padding(1.5)
            shape.fill(Color.black.opacity(0.063))
            ArenaBadgeSideBorder()
                .stroke(border, lineWidth: 2)
                .padding(1)
            shape.fill(LinearGradient(gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0.533), location: 0),
                .init(color: Color.black.opacity(0), location: 0.3)
            ]), startPoint: .top, endPoint: .bottom))
        }
    }

    /// Drawn centred and overflowing a narrow badge, exactly as HDT's
    /// IgnoreSizeDecorator does, then masked by the caller's clip.
    @ViewBuilder
    private var texture: some View {
        if let image = NSImage(named: isUnderground ? "arena-cell-bg-underground" : "arena-cell-bg") {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: textureSize.width, height: textureSize.height)
        }
    }
}

/// The size HDT draws `arena_cell_bg` at behind a badge. It is not the asset's own
/// size in either case - the hero row paints it at 156x52 and the card row at half
/// that, so the same texture reads at a different scale on each.
@available(macOS 10.15, *)
private enum ArenaBadgeTexture {
    static let hero = CGSize(width: 156, height: 52)
    static let card = CGSize(width: 78, height: 26)
}

/// The left, bottom and right edges only, with the bottom corners rounded - an
/// open path, so stroking it leaves the top edge bare like `BorderThickness`
/// with a zero top.
@available(macOS 10.15, *)
struct ArenaBadgeSideBorder: Shape {
    var radius: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.maxY),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// Rounded on the bottom two corners only, as XAML's `CornerRadius="0,0,3,3"`.
@available(macOS 10.15, *)
struct UnevenRoundedCornersShape: Shape {
    var bottomLeading: CGFloat = 0
    var bottomTrailing: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailing))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - bottomTrailing, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bottomLeading, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeading),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - card option

/// One of the three offered cards. The card art itself is Hearthstone's - all this
/// draws is the score plate and the badges that hang under it.
@available(macOS 10.15, *)
struct ArenaPickSingleCardOptionView: View {
    @ObservedObject var viewModel: ArenaPickSingleCardOptionViewModel
    /// Which of the three offered cards this is, so its badges can name the
    /// hover-visible regions they report.
    let index: Int
    let showScore: Bool
    let showRelatedCards: Bool
    let showSynergy: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            if showScore {
                ArenaPlaqueView(viewModel: viewModel.plaqueViewModel)
                    .padding(.top, 595)
            }

            badgeRow
        }
    }

    /// HDT lays the row out at 561 whether or not the card carries a multi-tribe
    /// banner. What changes is the clip: on a multi-tribe card the clip box moves
    /// down 4pt and the row moves up 4pt inside it, so the banner - which overhangs
    /// the bottom of the card art - reads as covering the badges' top edge.
    private var badgeRow: some View {
        let clip: CGFloat = viewModel.isMultiTribe ? 4 : 0
        // Only the row is clipped, not the plate above it: WPF's ClipToBounds is
        // scoped to the one Grid, where `.clipped()` would take everything under it.
        return badges
            .padding(.top, -clip)
            .clipped()
            .padding(.top, 561 + clip)
    }

    /// Three badges, always drawn and dimmed to 20% when they do not apply - HDT
    /// keeps the row a fixed width so it does not jump between picks. The first two
    /// are gated on the related-cards setting and the third on synergies.
    ///
    /// HDT has a fourth element here, a white circle showing the synergy count at
    /// `Margin="180,580"`, but its `Opacity` is pinned to 0 with nothing to animate
    /// it, so it never appears. It is left out rather than ported invisible.
    private var badges: some View {
        HStack(spacing: 4) {
            if showRelatedCards {
                relatedCardsBadge
                infoBadge
            }
            if showSynergy {
                improvementsBadge
            }
        }
    }

    /// Lit when the pick generates or relates to other cards.
    private var relatedCardsBadge: some View {
        ArenaOptionBadge(foreground: viewModel.badgeForegroundColor,
                         border: viewModel.badgeBorderColor,
                         isUnderground: viewModel.isUnderground,
                         textureSize: ArenaBadgeTexture.card,
                         dimmed: !viewModel.hasRelatedCards) {
            ArenaCardGlyph()
                .fill(viewModel.badgeForegroundColor)
                .frame(width: ArenaCardGlyph.width, height: ArenaCardGlyph.height)
                .shadow(color: .black.opacity(0.4), radius: 4)
        }
        .arenaOverlayTooltip(.relatedCards(index),
                             runs: [ArenaTooltipRun(
                                text: String.localizedString("ArenaPick_SingleCard_HasRelatedCards", comment: ""))],
                             isEnabled: viewModel.hasRelatedCards)
    }

    /// Lit when the pick carries an advisory the bottom panel spells out. HDT sets
    /// this one in Chunkfive, nudged 2pt down to sit on the badge's optical centre.
    private var infoBadge: some View {
        ArenaOptionBadge(foreground: viewModel.badgeForegroundColor,
                         border: viewModel.badgeBorderColor,
                         isUnderground: viewModel.isUnderground,
                         textureSize: ArenaBadgeTexture.card,
                         dimmed: !viewModel.hasInfo) {
            Text(verbatim: "i")
                .font(.custom("ChunkFive", size: 18))
                .foregroundColor(viewModel.badgeForegroundColor)
                .fixedSize()
                .padding(.top, 2)
                .shadow(color: .black.opacity(0.4), radius: 4)
        }
        .arenaOverlayTooltip(.additionalInfo(index),
                             runs: [ArenaTooltipRun(
                                text: String.localizedString("ArenaPick_SingleCard_HasAdditionalInfo", comment: ""))],
                             isEnabled: viewModel.hasInfo)
    }

    /// How many drafted cards the pick interacts with. While the bottom panel is
    /// highlighting improvements HDT turns the icon, the count and the border white
    /// - the `BoostIconWhite` swap, which here is just a different fill.
    private var improvementsBadge: some View {
        let highlighted = viewModel.highlightImprovements
        let tint = highlighted ? Color.white : viewModel.badgeForegroundColor
        return ArenaOptionBadge(foreground: tint,
                                border: highlighted ? .white : viewModel.badgeBorderColor,
                                isUnderground: viewModel.isUnderground,
                                textureSize: ArenaBadgeTexture.card,
                                dimmed: !viewModel.showSynergy) {
            HStack(spacing: 0) {
                ArenaBoostGlyph()
                    .fill(tint)
                    .frame(width: ArenaBoostGlyph.width, height: ArenaBoostGlyph.height)
                    .shadow(color: .black.opacity(0.4), radius: 4)
                Text(verbatim: "\(viewModel.synergyCount)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(tint)
                    .fixedSize()
                    .padding(.leading, 2)
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }
        }
        .arenaOverlayTooltip(.improvements(index),
                             runs: [ArenaTooltipRun(
                                text: String.localizedString("ArenaPick_SingleCard_ImprovesOrImprovedByCards",
                                                             comment: ""))],
                             isEnabled: viewModel.showSynergy)
    }
}

// MARK: - hero option

/// One offered hero, hero power, or dual-class hero: a tier plate over the card,
/// and win/pick rates under it.
@available(macOS 10.15, *)
struct ArenaPickSingleHeroOptionView: View {
    @ObservedObject var viewModel: ArenaPickSingleHeroOptionViewModel

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            ArenaPlaqueView(viewModel: viewModel.plaqueViewModel)
                .padding(.top, viewModel.plaqueTop)

            if viewModel.hasStats {
                rates.padding(.top, viewModel.statsTop)
            }
        }
        .padding(.leading, viewModel.leadingInset)
        .padding(.trailing, viewModel.trailingInset)
    }

    private var rates: some View {
        HStack(spacing: 4) {
            ArenaOptionBadge(foreground: viewModel.badgeForegroundColor,
                             border: viewModel.badgeBorderColor,
                             isUnderground: viewModel.isUnderground,
                             textureSize: ArenaBadgeTexture.hero,
                             dimmed: false) {
                rateLabel(String.localizedString("ArenaPick_SingleHero_WinRate", comment: ""),
                          value: viewModel.winrate)
            }
            ArenaOptionBadge(foreground: viewModel.badgeForegroundColor,
                             border: viewModel.badgeBorderColor,
                             isUnderground: viewModel.isUnderground,
                             textureSize: ArenaBadgeTexture.hero,
                             dimmed: false) {
                rateLabel(String.localizedString("ArenaPick_SingleHero_PickRate", comment: ""),
                          value: viewModel.pickrate)
            }
        }
    }

    private func rateLabel(_ label: String, value: Double) -> some View {
        // verbatim + fixedSize so the percentage is never locale-formatted or
        // truncated inside the badge.
        HStack(spacing: 3) {
            Text(verbatim: label)
                .font(.system(size: 14))
            Text(verbatim: "\(Int(value.rounded()))%")
                .font(.system(size: 14, weight: .bold))
        }
        .fixedSize()
        .padding(.leading, 2)
        .shadow(color: .black.opacity(0.4), radius: 4)
    }
}
