//
//  BattlegroundsCompositionStatsRowViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompositionStatsRowViewModel: ViewModel {
    private let _firstPlacePercent: Double
    private let _maxPercentage: Double
    private let _avgPlacement: Double
    private let _minionDbfId: Int
    
    init(_ name: String, _ minionDbfId: Int, _ firstPlacePercent: Double, _ avgPlacement: Double, _ maxPercentage: Double) {
        self.name = name
        _firstPlacePercent = firstPlacePercent
        _maxPercentage = round(10.0 * maxPercentage) / 10.0
        _avgPlacement = round(100.0 * avgPlacement) / 100.0
        _minionDbfId = minionDbfId
    }
    
    let name: String
    
    var minionDbfId: Int {
        return _minionDbfId
    }
    
    var maxBarPercentage: Double {
        return _maxPercentage
    }
    var firstPlacePercent: Double {
        return _firstPlacePercent
    }
    var avgPlacement: String {
        return String(format: "%.2f", _avgPlacement)
    }
    
    var avgPlacementColor: String {
        let pivot = 4.5
        let factor = 1.0
        
        return Helper.getColorString(mode: Helper.ColorStringMode.BATTLEGROUNDS, delta: (pivot - _avgPlacement) * 100.0 / 3.5 * factor, intensity: 75, saturationMultiplier: 1.3)
    }
}
