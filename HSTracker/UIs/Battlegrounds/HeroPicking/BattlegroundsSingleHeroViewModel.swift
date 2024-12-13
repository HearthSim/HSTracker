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
    var compositionsVisibility = false
    
    private(set) var heroDbfId: Int?
        
    init(stats: BattlegroundsHeroPickStats.BattlegroundsSingleHeroPickStats?, onPlacementHover: @escaping ((_ isVisible: Bool) -> Void)) {
        heroDbfId = stats?.hero_dbf_id
        bgsHeroHeaderVM = BattlegroundsHeroHeaderViewModel(tier: stats?.tier_v2, avgPlacement: stats?.avg_placement ?? 0.0, pickRate: stats?.pick_rate ?? 0.0, placementDistribution: stats?.placement_distribution ?? Array(repeating: 0.0, count: 8), onPlacementHover: onPlacementHover)
        if let firstPlaceCompPopularity = stats?.first_place_comp_popularity {
            bgsCompsPopularityVM = BattlegroundsCompositionPopularityViewModel(compsData: firstPlaceCompPopularity)
        } else {
            bgsCompsPopularityVM = nil
        }
        // Hide the "No composition data" message in Duos (unless we start having Comp data there).
        let game = AppDelegate.instance().coreManager.game
        compositionsVisibility = game.isBattlegroundsDuosMatch() && bgsCompsPopularityVM == nil ? false : true
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
