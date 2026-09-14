//
//  ArenaPickHelperView.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// The Arenasmith draft overlay. Port of HDT's `ArenaPickHelper.xaml`.
///
/// Authored at HDT's 1440x1080 reference and hosted on `RootOverlayView`'s scaled
/// canvas, which applies the same `height / 1080` factor HDT's
/// `_arenaOverlayBehavior` does.
@available(macOS 10.15, *)
struct ArenaPickHelperView: View {
    @ObservedObject var viewModel: ArenaPickHelperViewModel
    /// Reported upward so the window can match the cursor against it.
    @Binding var bottomPanelFrame: CGRect?
    /// Likewise for the direction funnel, as a polygon rather than a rect.
    @Binding var directionTriggerShape: [CGPoint]
    /// The three wedges leading across to the deck rail, and the rail's own frame.
    @Binding var cardListDirectionShapes: [[CGPoint]]
    @Binding var cardListTriggerFrame: CGRect?
    /// Every hover-visible region in the helper, for the window to sample against.
    @Binding var tooltipRegions: [ArenaTooltipRegion]

    // HDT's outer grid: 3.25* for the pick area, 1* for the deck rail.
    private static let referenceWidth: CGFloat = 1440
    private static let referenceHeight: CGFloat = 1080
    private static let optionsFraction: CGFloat = 3.25 / 4.25

    // Measured against the live client rather than taken from HDT, whose shared
    // grid gives every row a 280.37 pitch: the game spaces the three hero arches
    // 306.8 reference units apart, centred on 544.2 rather than the 549.49 the
    // column maths lands on. The row keeps its own width and is nudged those few
    // units left, overhanging the column symmetrically. Card, hero-power and
    // dual-class rows are left on HDT's spacing - they have not been measured.
    private static let heroPitch: CGFloat = 306.8
    private static let heroRowCenter: CGFloat = 544.2

    private var optionsWidth: CGFloat { Self.referenceWidth * Self.optionsFraction }
    /// Centre of the 782-unit middle column, where an unshifted row lands.
    private var optionsColumnCenter: CGFloat { (optionsWidth / 1000) * 499 }
    private var railWidth: CGFloat { Self.referenceWidth - optionsWidth }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.isVisible {
                HStack(spacing: 0) {
                    ZStack {
                        optionsArea
                            .allowsHitTesting(false)
                        // HDT puts the bottom panel in the same column as the
                        // options, inset 60pt either side and 99pt up. It is the
                        // one part of the helper that takes mouse input.
                        ArenaBottomPanelView(viewModel: viewModel)
                    }
                    .frame(width: optionsWidth)
                    deckRail
                        .frame(width: railWidth)
                        .allowsHitTesting(false)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ArenaCardListTriggerKey.self,
                                    value: viewModel.enableCardListTrigger
                                        ? proxy.frame(in: .rootOverlayCanvas) : nil)
                            }
                        )
                }
                .frame(width: Self.referenceWidth, height: Self.referenceHeight, alignment: .topLeading)
                .transition(transition)

                tooltipBubble
            }
        }
        .frame(width: Self.referenceWidth, height: Self.referenceHeight, alignment: .topLeading)
        .coordinateSpace(name: "arenaPickHelper")
        .animation(.easeOut(duration: 0.3), value: viewModel.isVisible)
        // The funnel, mapped from this view's reference space into canvas pixels
        // so RootOverlayWindow can hit-test the cursor against it. Reported as an
        // empty shape when disabled, which is how it stops being re-enterable.
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ArenaDirectionTriggerKey.self,
                                value: directionTriggerPoints(in: proxy))
                    .preference(key: ArenaCardListDirectionKey.self,
                                value: cardListDirectionPoints(in: proxy))
            }
        )
        // Hit testing is disabled per-subtree above rather than here: the bottom
        // panel's card list has to receive scroll events, and a disabled ancestor
        // cannot be re-enabled by a descendant.
        .onPreferenceChange(ArenaBottomPanelHoverKey.self) { rect in
            bottomPanelFrame = rect
        }
        .onPreferenceChange(ArenaDirectionTriggerKey.self) { points in
            directionTriggerShape = points
        }
        .onPreferenceChange(ArenaCardListDirectionKey.self) { shapes in
            cardListDirectionShapes = shapes
        }
        .onPreferenceChange(ArenaCardListTriggerKey.self) { rect in
            cardListTriggerFrame = rect
        }
        .onPreferenceChange(ArenaTooltipRegionKey.self) { regions in
            tooltipRegions = regions
        }
    }

    /// The hovered region's tooltip, drawn here rather than on the region: both the
    /// badge row and the deck rail are clipped, and WPF's ToolTip escapes that by
    /// being a popup in its own window.
    ///
    /// HDT places these `Top` with a 5pt offset. The zero-height marker spanning
    /// the region's width lets the bubble grow upward and centre on it without this
    /// view knowing how tall it is.
    @ViewBuilder
    private var tooltipBubble: some View {
        if let target = viewModel.hoveredTooltip,
           let region = tooltipRegions.last(where: { $0.target == target }),
           region.isEnabled, !region.runs.isEmpty {
            Color.clear
                .frame(width: region.anchor.width, height: 0)
                .overlay(ArenaTooltipBubble(runs: region.runs).fixedSize(), alignment: .bottom)
                .offset(x: region.anchor.minX, y: region.anchor.minY - 5)
                .allowsHitTesting(false)
        }
    }

    /// HDT drives this with four storyboards keyed off `StateChange`; entering the
    /// draft from the landing screen slides in from the right, leaving slides back
    /// out, and everything else cross-fades.
    private var transition: AnyTransition {
        switch viewModel.stateChange {
        case .slideIn, .slideOut:
            return .move(edge: .trailing).combined(with: .opacity)
        default:
            return .opacity
        }
    }

    // MARK: options

    private var optionsArea: some View {
        // Inside the pick area HDT splits 108 / 782 / 110; the three options live
        // in the middle column with a 10pt gutter either side.
        GeometryReader { geometry in
            let unit = geometry.size.width / 1000
            HStack(spacing: 0) {
                Spacer().frame(width: 108 * unit)
                options
                    .padding(.horizontal, 10)
                    .frame(width: 782 * unit)
                Spacer().frame(width: 110 * unit)
            }
        }
    }

    @ViewBuilder
    private var options: some View {
        if viewModel.showStats {
            if let heroStats = viewModel.heroStats, viewModel.heroPickVisible {
                heroRow(heroStats)
            } else if let heroPowerStats = viewModel.heroPowerStats, viewModel.heroPickVisible {
                heroRow(heroPowerStats)
            } else if let dualClassStats = viewModel.dualClassHeroStats, viewModel.heroPickVisible {
                heroRow(dualClassStats)
            } else if let cardStats = viewModel.cardStats {
                HStack(spacing: 0) {
                    ForEach(Array(cardStats.enumerated()), id: \.offset) { index, option in
                        ArenaPickSingleCardOptionView(viewModel: option,
                                                      index: index,
                                                      showScore: viewModel.arenasmithScoreVisible,
                                                      showRelatedCards: viewModel.relatedCardsVisible,
                                                      showSynergy: viewModel.synergiesVisible)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    /// HDT's three `CardListDirectionTrigger` polygons, mapped the same way the
    /// bottom funnel is. Each is reported empty unless its own trigger is enabled.
    private func cardListDirectionPoints(in proxy: GeometryProxy) -> [[CGPoint]] {
        guard viewModel.showStats else { return [[], [], []] }
        let frame = proxy.frame(in: .rootOverlayCanvas)
        guard frame.width > 0 else { return [[], [], []] }
        let scale = frame.width / Self.referenceWidth
        return (0..<3).map { index in
            guard viewModel.enableCardListDirectionTrigger(index) else { return [] }
            return ArenaPickHelperViewModel.cardListDirectionShape(forIndex: index).map {
                CGPoint(x: frame.minX + $0.x * scale, y: frame.minY + $0.y * scale)
            }
        }
    }

    private func directionTriggerPoints(in proxy: GeometryProxy) -> [CGPoint] {
        guard viewModel.enableBottomDirectionTrigger, viewModel.showBottom else { return [] }
        let frame = proxy.frame(in: .rootOverlayCanvas)
        guard frame.width > 0 else { return [] }
        let scale = frame.width / Self.referenceWidth
        return viewModel.bottomPanelDirectionShape.map {
            CGPoint(x: frame.minX + $0.x * scale, y: frame.minY + $0.y * scale)
        }
    }

    @ViewBuilder
    private func heroRow(_ stats: [ArenaPickSingleHeroOptionViewModel]) -> some View {
        if stats.first?.variant == .hero {
            HStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, option in
                    ArenaPickSingleHeroOptionView(viewModel: option)
                        .frame(width: Self.heroPitch)
                }
            }
            .offset(x: Self.heroRowCenter - optionsColumnCenter)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, option in
                    ArenaPickSingleHeroOptionView(viewModel: option)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: deck rail

    /// Overlays the game's own drafted-card list, scrolling in lockstep with it so
    /// each marker stays on its card.
    private var deckRail: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            if viewModel.isRedraft {
                VStack(spacing: 0) {
                    ForEach(viewModel.redraftTileViewModels) { tile in
                        ArenaDeckListTileView(viewModel: tile,
                                              showSynergy: viewModel.synergiesVisible,
                                              showDiscard: viewModel.redraftDiscardVisible)
                    }
                }
                .padding(.top, viewModel.redraftScrollOffset)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.tileViewModels) { tile in
                    ArenaDeckListTileView(viewModel: tile,
                                          showSynergy: viewModel.synergiesVisible,
                                          showDiscard: viewModel.redraftDiscardVisible)
                }
            }
            .padding(.top, viewModel.scrollOffset)
        }
        .clipped()
    }
}

/// One row of the deck rail: the highlight behind a card that interacts with the
/// hovered pick, the marker saying which way that interaction runs, and - while
/// editing a redraft deck - Arenasmith's score for the card.
@available(macOS 10.15, *)
struct ArenaDeckListTileView: View {
    @ObservedObject var viewModel: ArenaDeckListTileViewModel
    let showSynergy: Bool
    let showDiscard: Bool

    /// HDT's deck rows are 30pt tall inside a 40.75pt scroll step.
    private static let rowHeight: CGFloat = 40.75

    var body: some View {
        ZStack(alignment: .trailing) {
            Color.clear

            // One opacity for the highlight and the marker together, as HDT's
            // storyboard drives: eased in over 0.2s and cut on the way out, so
            // moving between picks does not leave a trail of fades. They stay laid
            // out at zero opacity - and so stay hoverable, which is how a discard
            // suggestion still has somewhere to hang its tooltip.
            ZStack(alignment: .trailing) {
                if showSynergy {
                    highlight
                }
                marker
            }
            .opacity(viewModel.showSynergy ? 1 : 0)
            .animation(viewModel.showSynergy ? .easeOut(duration: 0.2) : nil,
                       value: viewModel.showSynergy)

            // HDT only reveals the plate for tiles the redraft scoring actually
            // returned a score for, and styles rather than hides the rest.
            if showDiscard, viewModel.arenasmithScore != nil {
                scoreBadge
            }
        }
        .frame(height: Self.rowHeight)
    }

    // MARK: highlight

    /// A soft white wash across the row. HDT eases it in over 0.2s and cuts it on
    /// the way out, so moving between picks does not leave a trail of fades.
    private var highlight: some View {
        HStack(spacing: 0) {
            if let image = NSImage(named: "highlight-white") {
                Image(nsImage: image)
                    .resizable()
                    .frame(height: Self.rowHeight)
                    .padding(.leading, -4)
            }
        }
        .frame(height: Self.rowHeight)
        .padding(.trailing, 76)
        .clipped()
    }

    // MARK: marker

    /// The boost tab plus a thumbnail of the pick being hovered, so the row says
    /// which of the three offered cards it is reacting to. Only the tab is gated on
    /// the synergies setting; HDT keeps the thumbnail, and so the row's width,
    /// whatever the setting says.
    private var marker: some View {
        HStack(spacing: 0) {
            if showSynergy, viewModel.showSynergy {
                boostTab
            }
            hoveredCardTile
        }
        .frame(height: 30)
        // HDT hangs the tooltip off the marker itself, not the whole row.
        .arenaOverlayTooltip(.deckTile(cardId: viewModel.cardId,
                                       choiceIndex: viewModel.hoveredChoiceIndex),
                             runs: viewModel.tooltipRuns,
                             isEnabled: viewModel.hasTooltip)
        .padding(.trailing, 47)
    }

    /// HDT picks one of three arrangements by the exact synergy value: a left tab
    /// with the boost arrows inside it, a right one, or - when it runs both ways -
    /// two small tabs stacked, with no arrows.
    @ViewBuilder
    private var boostTab: some View {
        if viewModel.synergy == .both {
            VStack(spacing: 2) {
                ArenaBoostTabView(color: ArenaBoostTab.leftColor, pointsRight: false, small: true)
                    .frame(height: 10)
                ArenaBoostTabView(color: ArenaBoostTab.rightColor, pointsRight: true, small: true)
                    .frame(height: 10)
            }
            .padding(.trailing, -10)
        } else if viewModel.synergy.contains(.receives) {
            tabWithArrows(color: ArenaBoostTab.leftColor, pointsRight: false, arrowOffset: 2)
                .padding(.trailing, -8)
        } else {
            tabWithArrows(color: ArenaBoostTab.rightColor, pointsRight: true, arrowOffset: -2)
                .padding(.trailing, -12)
        }
    }

    /// The arrows sit inside the tab, nudged towards its blunt end.
    private func tabWithArrows(color: Color, pointsRight: Bool, arrowOffset: CGFloat) -> some View {
        ZStack {
            ArenaBoostTabView(color: color, pointsRight: pointsRight)
                .frame(height: 20)
            ArenaBoostGlyph()
                .fill(Color.white)
                .frame(width: 12 * ArenaBoostGlyph.viewBox.width / ArenaBoostGlyph.viewBox.height,
                       height: 12)
                .offset(x: arrowOffset)
        }
        .frame(height: 20)
    }

    /// 30x30 of the hovered pick's tile art, cropped to its left edge and boxed the
    /// way HDT boxes it - a rounded mask, a gradient falling from the left, and a
    /// white border open on the leading side.
    private var hoveredCardTile: some View {
        ZStack {
            // Identity is set here, by the parent: `.onAppear` fires once per
            // view identity, so without this the thumbnail would keep the first
            // pick's art as the cursor moves along the row of choices.
            ArenaTileImageView(cardId: viewModel.hoveredChoiceCardId)
                .id(viewModel.hoveredChoiceCardId ?? "")
                .frame(width: 112, height: 28)
                .padding(.leading, -64)
                .opacity(0.8)
                .frame(width: 26, height: 26, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .padding(2)

            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.4), location: 0),
                    .init(color: Color.black.opacity(0), location: 0.4)
                ]), startPoint: .leading, endPoint: .trailing))
                .padding(3)

            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color.white, lineWidth: 2)
        }
        .frame(width: 30, height: 30)
    }

    // MARK: score

    /// Arenasmith's score for a drafted card, shown while editing a redraft deck.
    /// A card it wants gone turns red and takes a cross over the plate.
    private var scoreBadge: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: viewModel.suggestRemove ? "#4f1719" : "#23272A"))
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color(hex: viewModel.suggestRemove ? "#f82a1e" : "#13171A"), lineWidth: 1))

            Text(verbatim: viewModel.arenasmithScore.map { "\(Int($0))" } ?? "–")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(viewModel.suggestRemove ? .white : Color.white.opacity(0.75))
                .fixedSize()
                .frame(maxWidth: .infinity)

            if viewModel.suggestRemove, let cross = NSImage(named: "tier-x") {
                Image(nsImage: cross)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26)
                    .padding(.leading, -12)
                    .padding(.top, 3)
            }
        }
        .frame(width: 34, height: 28)
        .padding(.trailing, 49)
    }
}

/// The hovered pick's tile art, loaded once per card id.
@available(macOS 10.15, *)
private struct ArenaTileImageView: View {
    let cardId: String?
    @SwiftUI.State private var image: NSImage?

    init(cardId: String?) {
        self.cardId = cardId
        // Seeded from the cache so a card that has already been shown does not
        // flash empty for a frame while the async load returns.
        _image = SwiftUI.State(initialValue: cardId.flatMap { ImageUtils.cachedTile(cardId: $0) })
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable()
            } else {
                Color.clear
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let cardId, !cardId.isEmpty else { return }
        if let cached = ImageUtils.cachedTile(cardId: cardId) {
            image = cached
            return
        }
        ImageUtils.tile(for: cardId) { loaded in
            DispatchQueue.main.async { image = loaded }
        }
    }
}

@available(macOS 10.15, *)
extension ArenaPickHelperViewModel {
    /// The overlay is only up while the player is on a draft screen with the
    /// feature enabled - HDT's `UpdateArenaPickHelperVisibility` plus the panel's
    /// own `ShowStats`.
    var isVisible: Bool {
        Settings.enableArenasmithOverlay && showStats
    }
}
