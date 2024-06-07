//
//  HeroPicking.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/4/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsHeroPickingViewModel: ViewModel {
    var isViewingTeammate: Bool {
        get {
            getProp(false)
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibility")
        }
    }
    
    var visibility: Bool {
        if !Settings.showBattlegroundsHeroPicking || isViewingTeammate {
            return false
        }
        return heroStats != nil ? true : false
    }
    
    var statsVisibility: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
//            onPropertyChanged("visibilityToggleIcon")
//            onPropertyChanged("visibilityToggleText")
        }
    }
    
    var heroStats: [BattlegroundsSingleHeroViewModel]? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibility")
        }
    }
    
    let message = OverlayMessageViewModel()
    
    func reset() {
        heroStats = nil
        isViewingTeammate = false
        statsVisibility = false
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
        
        statsVisibility = Settings.showBattlegroundsHeroPicking ? true : false
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
