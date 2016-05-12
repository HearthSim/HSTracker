//
//  Int.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 21/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

extension Int {

    var boolValue: Bool? {
        switch self {
        case 0: return false
        case 1: return true
        default: return nil
        }
    }

}
