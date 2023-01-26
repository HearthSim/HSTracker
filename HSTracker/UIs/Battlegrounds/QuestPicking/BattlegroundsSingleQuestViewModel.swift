//
//  BattlegroundsSingleQuestViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/11/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsSingleQuestViewModel: StatsHeaderViewModel {
    private(set) var compVM: BattlegroundsCompositionPopularityViewModel?
    
    init(stats: BattlegroundsQuestStats?) {
        super.init(tier: stats?.tier_r, avgPlacement: stats?.avg_final_placement_r, pickRate: stats?.fp_pick_rate_r)
        
        logger.debug("QUEST Tier: \(tier ?? 0), placement: \(avgPlacement ?? 0.0), pick rate: \(pickRate ?? 0.0)")
        
        if let stats = stats, stats.first_place_comps.count > 0, Settings.showBattlegroundsCompositionStats {
            compVM = BattlegroundsCompositionPopularityViewModel(compsData: stats.first_place_comps)
        }
    }
    
    var tierTooltipTitle: String {
        if let tier = tier, tier >= 1 &&  tier <= 4 {
            return NSLocalizedString("BattlegroundsHeroPicking_Header_Tier\(tier)Tooltip_Title", comment: "")
        }
        return ""
    }
    
    var tierTooltipText: String {
        if let tier = tier, tier >= 1 && tier <= 4 {
            return NSLocalizedString("BattlegroundsQuestPicking_Header_Tier\(tier)Tooltip_Desc", comment: "")
        }
        return ""
    }
}
