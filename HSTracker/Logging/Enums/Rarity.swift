//
//  Rarity.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Rarity: String, CaseIterable, Codable {
    case invalid,
         common,
         free,
         rare,
         epic,
         legendary,
         unknown_6
}
