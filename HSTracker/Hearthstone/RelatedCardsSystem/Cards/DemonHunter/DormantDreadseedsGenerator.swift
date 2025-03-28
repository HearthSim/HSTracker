//
//  DormantDreadseedsGenerator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DormantDreadseedsGenerator {
    fileprivate let dormantDreadseeds: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.DemonHunter.GrimHarvest_CrowDreadseedToken),
        Cards.any(byId: CardIds.NonCollectible.DemonHunter.GrimHarvest_HoundDreadseedToken),
        Cards.any(byId: CardIds.NonCollectible.DemonHunter.GrimHarvest_SerpentDreadseedToken)
    ]
    
    func getRelatedCards(player: Player) -> [Card?] {
        return dormantDreadseeds
    }
}
