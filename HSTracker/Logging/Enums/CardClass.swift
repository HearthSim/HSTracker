//
//  CardClass.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 13/07/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Unbox

enum CardClass: String, UnboxableEnum {
    case neutral,
    druid,
    hunter,
    mage,
    paladin,
    priest,
    rogue,
    shaman,
    warlock,
    warrior
    
    static func unboxFallbackValue() -> CardClass {
        return .neutral
    }
}
