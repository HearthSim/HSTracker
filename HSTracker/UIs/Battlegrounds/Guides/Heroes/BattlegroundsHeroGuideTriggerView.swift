//
//  BattlegroundsHeroGuideTriggerView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's GuidesTooltipTrigger (Windows/OverlayWindow.xaml) as positioned
// by SetHeroGuidesTrigger (Windows/OverlayWindow.Tooltips.cs): an invisible
// rectangle laid over the tooltip Hearthstone itself draws beside a hovered
// Battlegrounds hero, raising that hero's guide.
//
// This used to hang off the hero picker's own stats plates, because there was
// no way to know where the game had put the tooltip - HearthMirror had no
// getMulliganTooltipState. Now that it does, the trigger goes where HDT puts
// it, which also decouples the guide from the picking stats: HDT's trigger is
// its own element on the overlay canvas, so hovering a hero raises its guide
// whether or not the stats are shown or finished loading.
//
// A hover region rather than an interactive one, matching the
// IsOverlayHoverVisible HDT puts on the trigger - the click that picks the hero
// still falls through to Hearthstone.
@available(macOS 10.15, *)
struct BattlegroundsHeroGuideTriggerView: View {
    @ObservedObject var heroGuides: BattlegroundsHeroGuidesViewModel
    let canvasWidth: CGFloat
    // The hover regions the cursor is currently inside, from RootOverlayWindow.
    let hoveredRegions: Set<String>

    // SetHeroGuidesTrigger's own constants. Note they are not the ones
    // RegionDrawer uses for the opacity mask over these same heroes
    // (0.1725 / 0.0635) - HDT carries a second set here, and each is kept as
    // written.
    private static let heroWidth = 0.165
    private static let heroXSpacing = 0.075

    // vm.Top = Height * 0.21, vm.Width = Height * 0.47, vm.Height = Height * 0.40,
    // in a subtree whose canvas is already the 1080-tall reference.
    private static let top: CGFloat = 0.21 * 1080
    private static let width: CGFloat = 0.47 * 1080
    private static let height: CGFloat = 0.40 * 1080

    var body: some View {
        if let trigger = heroGuides.trigger, GuideTooltipCardView.isEnabled {
            ZStack(alignment: .topLeading) {
                Color.clear
                Color.clear
                    .frame(width: Self.width, height: Self.height)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: HoverRegionPreferenceKey.self,
                                value: [HoverRegion(id: HoverRegionID.heroGuideTrigger,
                                                    rect: proxy.frame(in: .rootOverlayCanvas))]
                            )
                        }
                    )
                    .overlay(tooltip(trigger), alignment: tooltipOnLeft(trigger) ? .leading : .trailing)
                    .padding(.leading, left(trigger))
                    .padding(.top, Self.top)
            }
            .frame(width: canvasWidth, height: 1080)
        }
    }

    // vm.Left = Helper.GetScaledXPos(heroX, Width, ScreenRatio). In this
    // subtree's canvas space that is 1440 * heroX + (canvasWidth - 1440) / 2 -
    // i.e. measured inside the 4:3 area, wherever it sits in a wider client.
    private func left(_ trigger: BattlegroundsHeroGuideTrigger) -> CGFloat {
        let zoneSize = 4.0
        let totalWidth = zoneSize * Self.heroWidth + (zoneSize - 1) * Self.heroXSpacing
        let leftEdge = 0.5 - totalWidth / 2

        let zoneIndex = CGFloat(max(trigger.zonePosition - 1, 0))
        let heroX = leftEdge + zoneIndex * (Self.heroWidth + Self.heroXSpacing - 0.005)
            - (trigger.tooltipOnRight ? 0 : Self.heroWidth)

        return SizeHelper.getScaledXPos(heroX, width: canvasWidth, ratio: 1440 / canvasWidth)
    }

    // vm.TooltipPlacement: the guide goes on the far side of the game's own
    // tooltip, except with buddies on, where the tooltip is wider and the sides
    // swap.
    private func tooltipOnLeft(_ trigger: BattlegroundsHeroGuideTrigger) -> Bool {
        return trigger.buddiesEnabled ? trigger.tooltipOnRight : !trigger.tooltipOnRight
    }

    // AlignmentMode.Center, the CardGridTooltipViewModel default: vertically
    // centred on the trigger and placed just outside the chosen edge.
    @ViewBuilder
    private func tooltip(_ trigger: BattlegroundsHeroGuideTrigger) -> some View {
        if hoveredRegions.contains(HoverRegionID.heroGuideTrigger),
           let cardId = trigger.tooltipCards.first,
           let guide = heroGuides.guide(heroPowerCardId: cardId) {
            GuideTooltipCardView(howToPlay: guide.howToPlay,
                                 favorableTribes: guide.favorableTribes,
                                 buddyGuide: guide.isBuddyGuidePublished ? guide.howToPlayBuddy : "")
                .offset(x: tooltipOnLeft(trigger) ? -GuideTooltipCardView.width : GuideTooltipCardView.width)
                .allowsHitTesting(false)
        }
    }
}
