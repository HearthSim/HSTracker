//
//  BattlegroundsQuestGuideTriggerView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's DiscoveryGuidesTooltipTrigger (Windows/OverlayWindow.xaml) as
// positioned by SetQuestGuidesTrigger (Windows/OverlayWindow.Tooltips.cs): an
// invisible rectangle laid over the tooltip Hearthstone itself draws for a
// hovered Battlegrounds quest reward, raising that reward's guide.
//
// This used to hang off the quest picker's own reward plates, because
// DiscoverStateWatcher carried no entity id to resolve the reward from. It does
// now, so the trigger goes where HDT puts it - which also decouples the guide
// from the picking stats, exactly as it did for the heroes.
//
// A hover region rather than an interactive one, matching the
// IsOverlayHoverVisible HDT puts on the trigger: the click that picks the
// reward still falls through to Hearthstone.
@available(macOS 10.15, *)
struct BattlegroundsQuestGuideTriggerView: View {
    @ObservedObject var questGuides: BattlegroundsQuestGuidesViewModel
    let canvasWidth: CGFloat
    // The hover regions the cursor is currently inside, from RootOverlayWindow.
    let hoveredRegions: Set<String>

    // SetQuestGuidesTrigger's own constants.
    private static let questPickWidth = 0.270
    private static let leftEdge = 0.117

    // vm.Top = Height * 0.22, vm.Width = Height * 0.30, vm.Height = Height * 0.55,
    // in a subtree whose canvas is already the 1080-tall reference.
    private static let top: CGFloat = 0.22 * 1080
    private static let width: CGFloat = 0.30 * 1080
    private static let height: CGFloat = 0.55 * 1080

    // vm.TooltipVerticalOffset = 32 * vm.Scale, with the scale this subtree
    // already applies.
    private static let tooltipVerticalOffset: CGFloat = 32

    var body: some View {
        if let trigger = questGuides.trigger, GuideTooltipCardView.isEnabled {
            ZStack(alignment: .topLeading) {
                Color.clear
                Color.clear
                    .frame(width: Self.width, height: Self.height)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: HoverRegionPreferenceKey.self,
                                value: [HoverRegion(id: HoverRegionID.questGuideTrigger,
                                                    rect: proxy.frame(in: .rootOverlayCanvas))]
                            )
                        }
                    )
                    // AlignmentMode.Start, unlike the hero trigger's Center:
                    // the guide's top edge lines up with the trigger's.
                    .overlay(tooltip(trigger), alignment: trigger.tooltipOnRight ? .topTrailing : .topLeading)
                    .padding(.leading, left(trigger))
                    .padding(.top, Self.top)
            }
            .frame(width: canvasWidth, height: 1080)
        }
    }

    // vm.Left = Helper.GetScaledXPos(questX, Width, ScreenRatio). In this
    // subtree's canvas space that is 1440 * questX + (canvasWidth - 1440) / 2 -
    // i.e. measured inside the 4:3 area, wherever it sits in a wider client.
    private func left(_ trigger: BattlegroundsQuestGuideTrigger) -> CGFloat {
        let questX = Self.leftEdge + CGFloat(trigger.zonePosition) * Self.questPickWidth
        return SizeHelper.getScaledXPos(questX, width: canvasWidth, ratio: 1440 / canvasWidth)
    }

    @ViewBuilder
    private func tooltip(_ trigger: BattlegroundsQuestGuideTrigger) -> some View {
        if hoveredRegions.contains(HoverRegionID.questGuideTrigger),
           let guide = questGuides.guide(rewardDbfId: trigger.rewardDbfId) {
            GuideTooltipCardView(howToPlay: guide.howToPlay,
                                 favorableTribes: guide.favorableTribes)
                .offset(x: trigger.tooltipOnRight ? GuideTooltipCardView.width : -GuideTooltipCardView.width,
                        y: Self.tooltipVerticalOffset)
                .allowsHitTesting(false)
        }
    }
}
