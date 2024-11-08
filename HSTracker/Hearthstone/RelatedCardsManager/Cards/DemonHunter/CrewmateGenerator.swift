//
//  CrewmateGenerator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CrewmateGenerator {
    
    private let crewmates: [Card?] = [
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_AdminCrewmateToken),
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_EngineCrewmateToken),
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_HelmCrewmateToken),
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_GunnerCrewmateToken),
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_MedicalCrewmateToken),
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_ReconCrewmateToken),
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_ResearchCrewmateToken),
        Cards.by(cardId: CardIds.NonCollectible.DemonHunter.VoroneiRecruiter_TacticalCrewmateToken)
    ]

    func getRelatedCards(player: Player) -> [Card?] {
        return crewmates
    }
}
