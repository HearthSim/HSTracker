//
//  BattlegroundsHeroHeaderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/18/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsHeroHeaderViewModel: StatsHeaderViewModel {
    
    let placementDistribution: [Double]?
    let onPlacementHover: ((_ isVisible: Bool) -> Void)?
    
    init(tier: Int?, avgPlacement: Double, pickRate: Double, placementDistribution: [Double], onPlacementHover: @escaping ((_ isVisible: Bool) -> Void)) {
        self.placementDistribution = placementDistribution
        self.onPlacementHover = onPlacementHover
        super.init(tier: tier, avgPlacement: avgPlacement, pickRate: pickRate)
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
    
    var placementDistributionVisibility: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
}
