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
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        
        return counter > 0 || companions[0] != CardIds.NonCollectible.Hunter.HufferLegacy
    }

    override func getCardsToDisplay() -> [String] {
        return companions
    }

    override func valueToShow() -> String {
        return "\(counter + 1)"
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

            if let card = Cards.by(dbfId: value, collectible: false) {
                switch tag {
                case .tag_script_data_num_4:
                    companions[0] = card.id
                    onCounterChanged()
                case .tag_script_data_num_5:
                    companions[1] = card.id
                    onCounterChanged()
                case .tag_script_data_num_6:
                    companions[2] = card.id
                    onCounterChanged()
                default:
                    break
                }
            }
            return
        }

        // Tag 4629 represents the specific counter for this mechanic
        if tag.rawValue != 4629 {
            return
        }

        if value == 0 {
            return
        }

        counter = value
    }
}
