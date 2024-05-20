//
//  HeroPicking.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/4/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsHeroPickingViewModel: ViewModel {
    var visibility: Bool {
        get {
            if !Settings.showBattlegroundsHeroPicking {
                return false
            }
            return getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
    
    var heroStats: [BattlegroundsSingleHeroViewModel]? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
        }
    }
    
    let message = OverlayMessageViewModel()
    
    func reset() {
        heroStats = nil
        visibility = false
        message.clear()
    }
    
    var scaling: Double {
        get {
            return getProp(1.0)
        }
        set {
            setProp(newValue)
        }
    }
    
    var selectedHeroDbfId: Int {
        get {
            getProp(0)
        }
        set {
            setProp(newValue)
            guard let heroStats else {
                return
            }
            let selectedHeroIndex = heroStats.firstIndex { x in x.heroDbfId == newValue }
            
            if let selectedHeroIndex {
                let direction = (selectedHeroIndex >= heroStats.count / 2) ? -1 : 1
                for i in 0 ..< heroStats.count {
                    heroStats[i].setHiddenByHeroPower(i == selectedHeroIndex + direction)
                }
            } else {
                for i in 0 ..< heroStats.count {
                    heroStats[i].setHiddenByHeroPower(false)
                }
            }
        }
    }
    
    var statsText: String? {
        get {
            return getProp("")
        }
        set {
            setProp(newValue)
        }
    }
    
    @available(macOS 10.15.0, *)
    func setHeroStats(stats: [BattlegroundsHeroPickStats.BattlegroundsSingleHeroPickStats], parameters: [String: String]?, minMmr: Int?, anomalyadjusted: Bool) async {
        heroStats = stats.compactMap { x in BattlegroundsSingleHeroViewModel(stats: x, onPlacementHover: setPlacementVisible) }
        let filterValue = parameters?["mmrPercentile"]
        
        message.mmr(filterValue: filterValue, minMMR: minMmr, anomalyAdjusted: anomalyadjusted)
        
        visibility = true
        // TODO: statsVisibility
    }
    
    func setPlacementVisible(_ isVisible: Bool) {
        guard let heroStats else {
            return
        }
        let visibility = isVisible
        for hero in heroStats {
            hero.bgsHeroHeaderVM.placementDistributionVisibility = visibility
        }
    }
}
