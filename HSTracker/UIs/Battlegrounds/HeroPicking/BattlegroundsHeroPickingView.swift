//
//  BattlegroundsHeroPickingView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsHeroPicking.xaml: the row of stats plates drawn
// over the heroes offered at the start of a Battlegrounds game, with the MMR
// bracket the numbers come from underneath.
//
// The control covers HDT's whole overlay canvas - OverlayWindow.Update sets it
// to Width/scaling by Height/scaling at Canvas 0,0 with scaling = Height/1080 -
// which is exactly the space RootOverlayView's scaled subtree lays its children
// out in, so everything inside can keep the XAML's own alignments and margins.
//
// HDT's in-overlay show/hide toggle has no counterpart here: HSTracker gates the
// whole overlay on its own "Show hero picking stats" preference instead, which
// the toggle would have no way back from.
@available(macOS 10.15, *)
struct BattlegroundsHeroPickingView: View {
    @ObservedObject var viewModel: BattlegroundsHeroPickingViewModel
    // The loaded hero guides, for the tooltip a hovered hero raises.
    @ObservedObject var heroGuides: BattlegroundsHeroGuidesViewModel
    // The hover regions the cursor is currently inside, from RootOverlayWindow.
    let hoveredRegions: Set<String>
    let canvasWidth: CGFloat

    // Each hero is a Height="568" Width="266" Grid with Margin="37,0" in a
    // single-row UniformGrid, so its column is 37 + 266 + 37 wide.
    private static let cellWidth = BattlegroundsSingleHeroStatsView.size.width + 2 * 37

    // Gated in here rather than by the parent: RootOverlayView instantiates
    // this unconditionally so its @ObservedObject binding stays live.
    var body: some View {
        // The conditional is wrapped rather than being the body's own root so
        // the fade below has a container to transition inside of.
        ZStack {
            if viewModel.visibility, viewModel.statsVisibility, let heroStats = viewModel.heroStats {
                stats(heroStats)
            }
        }
    }

    private func stats(_ heroStats: [BattlegroundsSingleHeroViewModel]) -> some View {
        ZStack {
            heroes(heroStats)
            message
            guideTooltip(heroStats)
        }
        .frame(width: canvasWidth, height: 1080)
        // anim:FadeAnimation Direction="Down" Distance="20" Duration="0:0:0.2":
        // appearing, it starts 20pt above where it belongs and comes down into
        // place as it fades up (GetTransformAnimation gives Direction.Down an
        // offset of -Distance). Driven by the withAnimation the view model wraps
        // its own stats assignment in.
        .transition(AnyTransition.opacity.combined(with: .offset(x: 0, y: -20)))
    }

    // The ItemsControl, inside a Grid with Margin="14,57,0,0" that is centred
    // both ways - so it sits half of each of those margins right of and below
    // the centre of the canvas.
    private func heroes(_ heroStats: [BattlegroundsSingleHeroViewModel]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(heroStats.enumerated()), id: \.offset) { index, hero in
                BattlegroundsSingleHeroStatsView(viewModel: hero,
                                                 guideRegionId: HoverRegionID.heroGuide(index))
                    .frame(width: Self.cellWidth, height: BattlegroundsSingleHeroStatsView.size.height)
            }
        }
        .offset(x: Self.rowOffsetX, y: 57 / 2)
    }

    // MARK: - Hero guide tooltip

    // HDT raises this from its own SetHeroGuidesTrigger, a hover-only rectangle
    // it positions over the offered hero from the game's mulligan tooltip
    // state. HSTracker has no such watcher, so the sensor is the hero's own
    // slot in this overlay - which is laid out over that same hero - and only
    // the placement is taken from HDT: vm.Top = Height * 0.21 and the card
    // beside the hovered hero, on whichever side has room for it.
    private static let guideTop: CGFloat = 0.21 * 1080
    private static let guideGap: CGFloat = 8
    private static let rowOffsetX: CGFloat = 14 / 2

    @ViewBuilder
    private func guideTooltip(_ heroStats: [BattlegroundsSingleHeroViewModel]) -> some View {
        if GuideTooltipCardView.isEnabled,
           let index = hoveredIndex(count: heroStats.count),
           let dbfId = heroStats[index].heroDbfId,
           let guide = heroGuides.guide(dbfId: dbfId) {
            ZStack(alignment: .topLeading) {
                Color.clear
                GuideTooltipCardView(howToPlay: guide.howToPlay,
                                     favorableTribes: guide.favorableTribes,
                                     buddyGuide: guide.isBuddyGuidePublished ? guide.howToPlayBuddy : "")
                    .padding(.leading, guideLeft(index: index, count: heroStats.count))
                    .padding(.top, Self.guideTop)
            }
            .frame(width: canvasWidth, height: 1080)
            .allowsHitTesting(false)
        }
    }

    private func hoveredIndex(count: Int) -> Int? {
        return (0..<count).first { hoveredRegions.contains(HoverRegionID.heroGuide($0)) }
    }

    // The hovered hero's own column, worked back from the centred row, and then
    // the card just outside it - to its right for the heroes in the left half
    // of the row, to its left for the rest, so the card always stays on screen.
    private func guideLeft(index: Int, count: Int) -> CGFloat {
        let rowCentre = canvasWidth / 2 + Self.rowOffsetX
        let cardCentre = rowCentre + (CGFloat(index) - CGFloat(count - 1) / 2) * Self.cellWidth
        let halfCard = BattlegroundsSingleHeroStatsView.size.width / 2
        if index < count / 2 {
            return cardCentre + halfCard + Self.guideGap
        }
        return cardCentre - halfCard - Self.guideGap - GuideTooltipCardView.width
    }

    // HorizontalAlignment="Center" VerticalAlignment="Bottom"
    // Margin="738 0 0 13": 13pt off the bottom of the canvas, and half of that
    // left margin right of its centre.
    private var message: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            OverlayMessageView(text: viewModel.message.text)
                .offset(x: 738 / 2)
                .padding(.bottom, 13)
        }
    }
}
