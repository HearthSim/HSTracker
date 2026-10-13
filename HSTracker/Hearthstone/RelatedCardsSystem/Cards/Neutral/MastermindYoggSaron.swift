//
//  MastermindYoggSaron.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable inclusive_language
// "Old God. Battlecry: End your turn. Yogg-saron takes an extra turn for you. (Once per game)"
class MastermindYoggSaron: ICardWithRelatedCards {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.MastermindYoggSaron
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.NonCollectible.Neutral.MastermindYoggSaron_BrainOfYoggSaronToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.MastermindYoggSaron_MadnessOfYoggSaronToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.MastermindYoggSaron_AscentOfYoggSaronToken),
            Cards.any(byId: CardIds.NonCollectible.Neutral.MastermindYoggSaron_DomainOfYoggSaronToken)
        ]
    }
}
//swiftlint:enable inclusive_language
