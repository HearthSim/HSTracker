//
//  StatsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

// Assuming BaseCounter is already translated as shown earlier
class StatsCounter: BaseCounter {
    private var _attack: Int = 0
    var attackCounter: Int {
        get {
            return _attack
        }
        set {
            if _attack != newValue {
                _attack = newValue
                onCounterChanged()
                onPropertyChanged()
            }
        }
    }

    private var _health: Int = 0
    var healthCounter: Int {
        get {
            return _health
        }
        set {
            if _health != newValue {
                _health = newValue
                onCounterChanged()
                onPropertyChanged()
            }
        }
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
        self.attackCounter = 0
        self.healthCounter = 0
    }
}
