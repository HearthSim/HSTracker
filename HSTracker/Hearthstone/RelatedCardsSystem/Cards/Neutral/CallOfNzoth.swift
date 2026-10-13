//
//  CallOfNzoth.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Discover a Deathrattle minion that costs (5) or more to summon."
// N'Zoth, Dream's End's ability.
class CallOfNzoth: ClassOrNeutralCostAtLeast5DeathrattleMinionPool {
    override func getCardId() -> String { CardIds.NonCollectible.Neutral.NZothDreamsEnd_CallOfNzothToken }
}
