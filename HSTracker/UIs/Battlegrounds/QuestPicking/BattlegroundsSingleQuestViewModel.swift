//
//  BattlegroundsSingleQuestViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/11/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

// Port of HDT's BattlegroundsSingleQuestViewModel
// (Controls/Overlay/Battlegrounds/QuestPicking/BattlegroundsSingleQuestViewModel.cs):
// one offered reward's stats header plus the compositions that win with it.
class BattlegroundsSingleQuestViewModel: StatsHeaderViewModel {
    private(set) var compVM: BattlegroundsCompositionPopularityViewModel?
    
    init(stats: BattlegroundsQuestStats?) {
        super.init(tier: stats?.tier_r, avgPlacement: stats?.avg_final_placement_r, pickRate: stats?.fp_pick_rate_r)
        
        logger.debug("QUEST Tier: \(tier ?? 0), placement: \(avgPlacement ?? 0.0), pick rate: \(pickRate ?? 0.0)")
        
        if let stats = stats, stats.first_place_comps.count > 0 {
            compVM = BattlegroundsCompositionPopularityViewModel(compsData: stats.first_place_comps)
        }
    }
}
