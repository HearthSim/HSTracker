//
//  BattlegroundsDiscoveryGuideTriggerView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's DiscoveryGuidesTooltipTrigger (Windows/OverlayWindow.xaml): an
// invisible rectangle laid over the tooltip Hearthstone itself draws for a
// hovered Battlegrounds trinket or quest reward, raising that card's guide.
// One element for both, as HDT has it - the two can never be up at once, since
// a hovered choice is one card.
//
// Both used to hang off the pickers' own plates: the quest one because
// DiscoverStateWatcher carried no entity id, the trinket one for no reason
// beyond that being how the AppKit view it replaced worked. The trinket plate
// also had to claim clicks to get a hover out of SwiftUI, which HDT's trigger
// never does (IsOverlayHoverVisible) - so the click that picks a trinket now
// falls through to Hearthstone again.
@available(macOS 10.15, *)
struct BattlegroundsDiscoveryGuideTriggerView: View {
    @ObservedObject var discoveryGuides: BattlegroundsDiscoveryGuidesViewModel
    @ObservedObject var trinketGuides: BattlegroundsTrinketGuidesViewModel
    @ObservedObject var questGuides: BattlegroundsQuestGuidesViewModel
    let canvasWidth: CGFloat
    // The hover regions the cursor is currently inside, from RootOverlayWindow.
    let hoveredRegions: Set<String>

    var body: some View {
        if let trigger = discoveryGuides.trigger, GuideTooltipCardView.isEnabled {
            ZStack(alignment: .topLeading) {
                Color.clear
                Color.clear
                    .frame(width: trigger.width * 1080, height: trigger.height * 1080)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: HoverRegionPreferenceKey.self,
                                value: [HoverRegion(id: HoverRegionID.discoveryGuideTrigger,
                                                    rect: proxy.frame(in: .rootOverlayCanvas))]
                            )
                        }
                    )
                    .overlay(tooltip(trigger), alignment: alignment(trigger))
                    // vm.Left = Helper.GetScaledXPos(x, Width, ScreenRatio). In
                    // this subtree's canvas space that is
                    // 1440 * x + (canvasWidth - 1440) / 2 - i.e. measured
                    // inside the 4:3 area, wherever it sits in a wider client.
                    .padding(.leading, SizeHelper.getScaledXPos(trigger.x, width: canvasWidth,
                                                                ratio: 1440 / canvasWidth))
                    .padding(.top, trigger.top * 1080)
            }
            .frame(width: canvasWidth, height: 1080)
        }
    }

    // The corner of the trigger the guide hangs off, before being pushed
    // outside it by the offset below.
    private func alignment(_ trigger: BattlegroundsDiscoveryGuideTrigger) -> Alignment {
        switch trigger.placement {
        case .left:
            return trigger.alignsToStart ? .topLeading : .leading
        case .right:
            return trigger.alignsToStart ? .topTrailing : .trailing
        case .bottom:
            return .bottom
        }
    }

    @ViewBuilder
    private func tooltip(_ trigger: BattlegroundsDiscoveryGuideTrigger) -> some View {
        if hoveredRegions.contains(HoverRegionID.discoveryGuideTrigger) {
            card(trigger.content)
                .offset(x: horizontalOffset(trigger),
                        y: verticalOffset(trigger))
                .allowsHitTesting(false)
        }
    }

    private func horizontalOffset(_ trigger: BattlegroundsDiscoveryGuideTrigger) -> CGFloat {
        switch trigger.placement {
        case .left:
            return -GuideTooltipCardView.width
        case .right:
            return GuideTooltipCardView.width
        case .bottom:
            return 0
        }
    }

    private func verticalOffset(_ trigger: BattlegroundsDiscoveryGuideTrigger) -> CGFloat {
        return trigger.verticalOffset
    }

    @ViewBuilder
    private func card(_ content: BattlegroundsDiscoveryGuideTrigger.Content) -> some View {
        switch content {
        case .trinket(let dbfId):
            let guide = trinketGuides.guide(dbfId: dbfId)
            GuideTooltipCardView(howToPlay: guide?.published_guide ?? "",
                                 favorableTribes: Self.favorableTribes(guide?.favorable_tribes))
        case .questReward(let dbfId):
            if let guide = questGuides.guide(rewardDbfId: dbfId) {
                GuideTooltipCardView(howToPlay: guide.howToPlay,
                                     favorableTribes: guide.favorableTribes)
            }
        }
    }

    // The trinket guides model hands back raw race numbers, which the trinket
    // plate used to filter against the lobby itself.
    private static func favorableTribes(_ raceNumbers: [Int]?) -> [Race] {
        let availableRaces = Set(AppDelegate.instance().coreManager.game.availableRaces ?? [])
        return (raceNumbers ?? []).compactMap { raceNumber -> Race? in
            guard raceNumber >= 0, raceNumber < Race.allCases.count else { return nil }
            let race = Race.allCases[raceNumber]
            return availableRaces.contains(race) ? race : nil
        }
    }
}
