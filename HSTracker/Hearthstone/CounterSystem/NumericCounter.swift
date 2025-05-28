//
//  NumericCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

// Assuming BaseCounter is already translated as shown earlier
class NumericCounter: BaseCounter {
    private var _counter: Int = 0
    var counter: Int {
        get {
            return _counter
        }
        set {
            if _counter != newValue {
                _counter = newValue
                onCounterChanged()
                onPropertyChanged()
            }
        }
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
        self.counter = 0
    }

    override func valueToShow() -> String {
        return String(counter)
    }
    
    var lastEntityToCount: Entity?
    
    func discountIfCantPlay(tag: GameTag, value: Int, entity: Entity) -> Bool {
        if lastEntityToCount == nil || entity.id != lastEntityToCount?.id || tag != .cant_play || value <= 0 {
            return false
        }
        counter -= 1
        return true
    }
}
