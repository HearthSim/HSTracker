//
//  AnomalyGuideBadgeTriggerView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's SetAnomalyGuidesTrigger(string cardId) in
// Windows/OverlayWindow.Tooltips.cs - shown post-mulligan, driven by the
// game's own memory-read hover state (Game.onBigCardChange, mirroring HDT's
// BigCardState hover callback) rather than SwiftUI's .onHover: unlike
// AnomalyGuideMulliganTriggerView (mulligan-only, where that hover state
// isn't available), the persistent anomaly badge's hover is already reported
// by the same big-card watcher that drives related-card tooltips - see
// BattlegroundsAnomalyGuidesViewModel.updateHoveredCard.
//
// No InteractiveRegionPreferenceKey/.onHover here: the hover being tracked
// happens over Hearthstone's own rendering, not over this overlay window, so
// there's nothing for RootOverlayWindow's click-through mechanism to gate -
// this view only ever reacts to state, never intercepts a click.
@available(macOS 10.15, *)
struct AnomalyGuideBadgeTriggerView: View {
    @ObservedObject var anomalyGuides: BattlegroundsAnomalyGuidesViewModel
    let geometrySize: CGSize

    var body: some View {
        if AppDelegate.instance().coreManager.game.isBattlegroundsMatch(),
           AppDelegate.instance().coreManager.game.isMulliganDone(),
           let anomalyCard = anomalyGuides.hoveredAnomalyCard {
            let scale = geometrySize.height / 1080
            let left = SizeHelper.getScaledXPos(0.90, width: geometrySize.width, ratio: SizeHelper.screenRatio)
            let top = geometrySize.height * 0.33
            let height = geometrySize.height * 0.1
            let guide = anomalyGuides.guide(dbfId: anomalyCard.dbfId)

            // HDT: TooltipPlacement=Bottom, TooltipHorizontalOffset=-340*scale,
            // TooltipVerticalOffset=100*scale, relative to the (fixed) trigger
            // rect at (left, top, height, width=Height*0.13).
            GuideTooltipCardView(howToPlay: guide?.published_guide ?? "", favorableTribes: Self.favorableTribes(guide))
                .offset(x: left - 340 * scale, y: top + height + 100 * scale)
                .allowsHitTesting(false)
        }
    }

    private static func favorableTribes(_ guide: BattlegroundsAnomalyGuide?) -> [Race] {
        let availableRaces = Set(AppDelegate.instance().coreManager.game.availableRaces ?? [])
        return (guide?.favorable_tribes ?? []).compactMap { raceNumber -> Race? in
            guard raceNumber >= 0, raceNumber < Race.allCases.count else { return nil }
            let race = Race.allCases[raceNumber]
            return availableRaces.contains(race) ? race : nil
        }
    }
}
