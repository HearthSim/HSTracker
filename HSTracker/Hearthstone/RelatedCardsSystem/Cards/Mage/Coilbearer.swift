//
//  Coilbearer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Discover a spell to put on top of your deck. It costs (2) less."
class Coilbearer: ClassOrNeutralSpellPool {
    override func getCardId() -> String { CardIds.Collectible.Mage.Coilbearer }
}
