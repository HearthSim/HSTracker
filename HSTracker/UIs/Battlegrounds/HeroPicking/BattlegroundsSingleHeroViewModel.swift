//
//  BattlegroundsSingleHeroViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/4/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

// Port of HDT's BattlegroundsSingleHeroViewModel
// (Controls/Overlay/Battlegrounds/HeroPicking/BattlegroundsSingleHeroViewModel.cs):
// one offered hero, which is just its stats header plus the dbf id the reroll
// path invalidates it by.
@available(macOS 10.15, *)
class BattlegroundsSingleHeroViewModel: Identifiable {
    let bgsHeroHeaderVM: BattlegroundsHeroHeaderViewModel

    private(set) var heroDbfId: Int?

    init(stats: BattlegroundsHeroPickStats.BattlegroundsSingleHeroPickStats?, onPlacementHover: @escaping ((_ isVisible: Bool) -> Void)) {
        heroDbfId = stats?.hero_dbf_id
        bgsHeroHeaderVM = BattlegroundsHeroHeaderViewModel(tier: stats?.tier_v2, avgPlacement: stats?.avg_placement, pickRate: stats?.pick_rate, placementDistribution: stats?.placement_distribution ?? Array(repeating: 0.0, count: 8), onPlacementHover: onPlacementHover)
    }
}
