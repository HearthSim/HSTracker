//
//  BattlegroundsSingleHeroStatsView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsSingleHeroStats.xaml: one offered hero's slot in
// the picking overlay - the stats plate docked to the top of it, and under that
// the space Hearthstone's own hero portrait shows through.
@available(macOS 10.15, *)
struct BattlegroundsSingleHeroStatsView: View {
    let viewModel: BattlegroundsSingleHeroViewModel
    // The id this hero's guide tooltip sensor reports itself under, so
    // RootOverlayWindow can say whether the cursor is over this hero.
    let guideRegionId: String

    // d:DesignHeight="568" d:DesignWidth="266", the size the picking overlay's
    // ItemTemplate gives each hero.
    static let size = CGSize(width: 266, height: 568)

    var body: some View {
        VStack(spacing: 0) {
            BattlegroundsHeroHeaderView(viewModel: viewModel.bgsHeroHeaderVM)
            // The hero portrait container: a transparent, IsHitTestVisible=
            // "False" Grid that only reserves the room the portrait occupies.
            // It doubles as the guide tooltip's sensor, since it is the part of
            // the card the hero itself is under - a hover region rather than an
            // interactive one, so the click that picks the hero still reaches
            // Hearthstone (HDT's own trigger is IsOverlayHoverVisible too).
            Color.clear
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: HoverRegionPreferenceKey.self,
                                               value: [HoverRegion(id: guideRegionId,
                                                                   rect: proxy.frame(in: .rootOverlayCanvas))])
                    }
                )
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}
