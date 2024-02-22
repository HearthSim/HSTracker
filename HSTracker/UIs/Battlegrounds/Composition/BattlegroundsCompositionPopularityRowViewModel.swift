//
//  BattlegroundsCompositionPopularityRowViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompositionPopularityRowViewModel {
    private let _popularity: Double
    private let _maxPopularity: Double
    private let _available: Bool
    
    init(name: String, minionDbfId: Int, available: Bool, popularity: Double, maxPopularity: Double) {
        self.name = name
        let minionCard = Cards.by(dbfId: minionDbfId, collectible: false)
        cardImage = minionCard?.id ?? ""
        _popularity = popularity
        _maxPopularity = maxPopularity
        _available = available
    }
    
    let cardImage: String
    
    let name: String
    
    var popularityBarValue: Double {
        return _popularity / _maxPopularity * 100.0
    }
    var popularityText: String {
        return String(format: "%.1f%%", _popularity)
    }
    var compositionAvailable: Bool {
        return _available
    }
    var compositionUnavailableVisibility: Bool {
        return !_available
    }
    var opacity: Double {
        return _available ? 1.0 : 0.5
    }
}
