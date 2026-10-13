//
//  ConstellarsCalling.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Choose a friendly minion. Summon a random minion of the same Cost."
class ConstellarsCalling: RelativeCostPoolCard {
    override func getCardId() -> String { CardIds.Collectible.Mage.ConstellarsCalling }
    override var costOffset: Int { 0 }
    override var affectsAllTargets: Bool { false }
}
