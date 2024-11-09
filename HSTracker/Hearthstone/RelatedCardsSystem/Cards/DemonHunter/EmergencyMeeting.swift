//
//  EmergencyMeeting.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class EmergencyMeeting: CrewmateGenerator, ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.EmergencyMeeting
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    required override init() { }
}
