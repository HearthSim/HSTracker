//
//  BattlegroundsTrinketPickingViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTrinketPickingViewModel: ViewModel {
    var choicesVisible: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibility")
        }
    }
    
    var visibility: Bool {
        return choicesVisible && trinketStats != nil && trinketStats?.count ?? 0 > 0
    }
    
    var statsVisibility: Bool {
        get {
            getProp(false)
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibilityToggleIcon")
            onPropertyChanged("visibilityToggleText")
        }
    }
    
    var visibilityToggleIcon: String {
        return statsVisibility ? "eye_slash" : "eye"
    }
    
    var visibilityToggleText: String {
        return statsVisibility ? "HIDE TRINKET STATS" : "SHOW TRINKET STATS"
    }
    
    var trinketStats: [StatsHeaderViewModel]? {
        get {
            return getProp([StatsHeaderViewModel]())
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibility")
        }
    }
    
    let message = OverlayMessageViewModel()
    
    func showErrorMessage() {
        message.error()
    }
    
    func showDisabledMessage() {
        message.disabled()
    }
    
    func reset() {
        trinketStats = nil
        message.clear()
    }
    
    func setTrinketStats(_ stats: [BattlegroundsTrinketPickStats.BattlegroundsSingleTrinketPickStats]) {
        trinketStats = stats.compactMap({ x in StatsHeaderViewModel(tier: x.tier, avgPlacement: x.avg_placement, pickRate: x.pick_rate)})
        
        statsVisibility = Settings.autoShowBattlegroundsTrinketPicking
    }
}
