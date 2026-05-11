//
//  AnimalCompanionCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class AnimalCompanionCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Hunter.AnimalCompanionCore
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Hunter.TalyaEarthstrider,
            CardIds.Collectible.Hunter.TamePet,
            CardIds.Collectible.Hunter.RoamFree,
            CardIds.Collectible.Hunter.MigratingElekk,
            CardIds.Collectible.Hunter.AnimalCompanionCore,
            CardIds.Collectible.Hunter.AnimalCompanionLegacy,
            CardIds.Collectible.Hunter.AnimalCompanionVanilla
        ]
    }

    var companions: [String] = [
        CardIds.NonCollectible.Hunter.HufferLegacy,
        CardIds.NonCollectible.Hunter.LeokkLegacy,
        CardIds.NonCollectible.Hunter.MishaLegacy
    ]

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }

        return counter > 3
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ? companions : []
    }

    override func valueToShow() -> String {
        return String(format: String.localizedString("Counter_AnimalCompanionCost", comment: ""), "\(counter)")
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        let controller = entity[.controller]
        let isPlayerController = controller == game.player.id
        guard isPlayerController == isPlayerCounter else { return }

        // Check for specific companion-generating spells
        let cardId = entity.cardId
        if cardId == CardIds.Collectible.Hunter.TamePet ||
           cardId == CardIds.Collectible.Hunter.MigratingElekk ||
           cardId == CardIds.Collectible.Hunter.RoamFree {
            
            guard tag == .tag_script_data_num_4 || tag == .tag_script_data_num_5 || tag == .tag_script_data_num_6 else {
                return
            }

            guard let card = Cards.by(dbfId: value, collectible: false) else { return }
            
            switch tag {
            case .tag_script_data_num_4:
                companions[0] = card.id
            case .tag_script_data_num_5:
                companions[1] = card.id
            case .tag_script_data_num_6:
                companions[2] = card.id
            default:
                break
            }
            counter = card.cost
        }
    }
}
