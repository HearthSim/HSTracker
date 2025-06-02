//
//  IncidiusCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class IncindiusCounter: ICardExtraInfo, Equatable {
    var counter = 0
    fileprivate(set) var turnPlayed = 0
    
    var cardNameSuffix: String? {
        return counter > 0 ? "(+\(counter))" : nil
    }
    
    init(_ turnPlayed: Int, _ counter: Int = 1) {
        self.turnPlayed = turnPlayed
        self.counter = counter
    }
    
    static func == (lhs: IncindiusCounter, rhs: IncindiusCounter) -> Bool {
        return lhs.turnPlayed == rhs.turnPlayed && lhs.counter == rhs.counter
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return IncindiusCounter(turnPlayed, counter)
    }
}
