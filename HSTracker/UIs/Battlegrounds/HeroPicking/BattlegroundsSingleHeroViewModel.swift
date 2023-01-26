//
//  BattlegroundsSingleHeroViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/4/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsSingleHeroViewModel: ViewModel {
    let bgsHeroHeaderVM: BattlegroundsHeroHeaderViewModel
    let bgsCompsPopularityVM: BattlegroundsCompositionPopularityViewModel?
    
    private(set) var heroDbfId: Int?
    private(set) var armorTier: Int?
    
    var armorTierTooltipRange: String? {
        guard let armorTier else {
            return nil
        }
        let (_min, _max) = (2...7 ~= armorTier) ? (armorTier, armorTier + 3) : (0, 0)
        return String(format: NSLocalizedString("BattlegroundsHeroPicking_Hero_ArmorTierTooltip_Range", comment: ""), _min, _max)
    }
    
    init(stats: BattlegroundsSingleHeroPickStats, onPlacementHover: @escaping ((_ isVisible: Bool) -> Void)) {
        heroDbfId = stats.hero_dbf_id
        armorTier = Cards.getBattlegroundsHeroFromDbfid(dbfId: stats.hero_dbf_id)?.battlegroundsArmorTier
        bgsHeroHeaderVM = BattlegroundsHeroHeaderViewModel(tier: stats.tier, avgPlacement: stats.avg_placement, pickRate: stats.pick_rate, placementDistribution: stats.placement_distribution, onPlacementHover: onPlacementHover)
        if stats.first_place_comp_popularity.count > 0 {
            bgsCompsPopularityVM = BattlegroundsCompositionPopularityViewModel(compsData: stats.first_place_comp_popularity)
        } else {
            bgsCompsPopularityVM = nil
        }
    }
    
    var heroPowerVisibility: Bool {
        get {
            return getProp(true)
        }
        set {
            setProp(newValue)
        }
    }
    
    func setHiddenByHeroPower(_ hidden: Bool) {
        heroPowerVisibility = hidden ? false : true
    }
}
