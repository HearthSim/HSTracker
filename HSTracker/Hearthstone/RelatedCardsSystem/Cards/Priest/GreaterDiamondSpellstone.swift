//
//  GreaterDiamondSpellstone.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class GreaterDiamondSpellstone: LesserDiamondSpellstone {
    override func getCardId() -> String {
        return CardIds.NonCollectible.Priest.LesserDiamondSpellstone_GreaterDiamondSpellstoneToken
    }
}
