//
//  IBoardEntity.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/06/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol IBoardEntity {
    var name: String { get }
    var cardId: String { get }
    var health: Int { get }
    var attack: Int { get }
    // number of attacks made this turn
    var attacksThisTurn: Int { get }
    // ability to attack this turn (some exceptions)
    var exhausted: Bool { get }
    // whether to include in damage calculation
    var include: Bool { get }
    // the zone the entity is in
    var zone: String { get }
}
