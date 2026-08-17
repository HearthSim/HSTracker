//
//  AnomalyGuideMulliganTriggerView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's AnomalyGuidesMulliganTrigger (Windows/OverlayWindow.xaml,
// positioned by SetAnomalyGuidesMulliganTrigger in
// Windows/OverlayWindow.Tooltips.cs). This isn't hovering an HSTracker-drawn
// element - it's an invisible region placed directly on top of wherever
// Hearthstone itself renders the anomaly icon during mulligan. HDT's own
// comment explains why: "This is only needed for anomaly during mulligan
// because there is no way to retrieve the 'hover action' by memory reading
// it" - elsewhere HDT positions guide tooltip triggers using a live
// memory-read hover state, but that isn't available during mulligan, so it
// fakes hover detection with a statically-positioned trigger instead.
//
// Positioned in real, post-scale pixel space (geometrySize, passed down from
// RootOverlayView's GeometryReader) rather than the 1080-reference scaled
// canvas other Guides content uses (e.g. GuidesTabsView) - HDT's own
// SetAnomalyGuidesMulliganTrigger computes Left via Helper.GetScaledXPos
// against the real WPF window Width and ScreenRatio, which is what
// SizeHelper.getScaledXPos mirrors; the 1080-reference canvas has already
// dropped that pillarbox correction; using it here would drift off the
// game's actual anomaly icon on any non-4:3 window.
@available(macOS 10.15, *)
struct AnomalyGuideMulliganTriggerView: View {
    @ObservedObject var anomalyGuides: BattlegroundsAnomalyGuidesViewModel
    let geometrySize: CGSize

    @SwiftUI.State private var isHovering = false

    var body: some View {
        if let anomalyCard = Self.mulliganAnomalyCard() {
            let scale = geometrySize.height / 1080
            let left = SizeHelper.getScaledXPos(0.635, width: geometrySize.width, ratio: SizeHelper.screenRatio)
            let top = geometrySize.height * 0.0825
            let height = geometrySize.height * 0.123
            let width = geometrySize.height * 0.1188
            let guide = anomalyGuides.guide(dbfId: anomalyCard.dbfId)

            Color.clear
                .frame(width: width, height: height)
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHovering = hovering
                }
                .overlay(tooltip(guide: guide, scale: scale, triggerHeight: height), alignment: .bottom)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: InteractiveRegionPreferenceKey.self, value: proxy.frame(in: .rootOverlayCanvas))
                    }
                )
                .offset(x: left, y: top)
        }
    }

    @ViewBuilder
    private func tooltip(guide: BattlegroundsAnomalyGuide?, scale: CGFloat, triggerHeight: CGFloat) -> some View {
        if isHovering {
            // HDT: TooltipPlacement=Bottom, TooltipHorizontalOffset=-600*scale,
            // TooltipVerticalOffset=20*scale.
            GuideTooltipCardView(howToPlay: guide?.published_guide ?? "", favorableTribes: Self.favorableTribes(guide))
                .offset(x: -600 * scale, y: triggerHeight + 20 * scale)
                .allowsHitTesting(false)
        }
    }

    private static func mulliganAnomalyCard() -> Card? {
        let game = AppDelegate.instance().coreManager.game
        guard game.isBattlegroundsMatch(), !game.isMulliganDone() else { return nil }
        guard let dbfId = BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: game.gameEntity) else { return nil }
        return Cards.by(dbfId: dbfId, collectible: false)
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
