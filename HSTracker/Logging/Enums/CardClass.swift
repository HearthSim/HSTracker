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
    case NEUTRAL,
    DRUID,
    HUNTER,
    MAGE,
    PALADIN,
    PRIEST,
    ROGUE,
    SHAMAN,
    WARLOCK,
    WARRIOR
    
    static func unboxFallbackValue() -> CardClass {
        return .NEUTRAL
    }
}