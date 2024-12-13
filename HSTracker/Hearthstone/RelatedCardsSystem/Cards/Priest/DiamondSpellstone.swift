//
//  DiamondSpellstone.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DiamondSpellstone: LesserDiamondSpellstone {
    override func getCardId() -> String {
        return CardIds.NonCollectible.Priest.LesserDiamondSpellstone_DiamondSpellstoneToken
    }
}
