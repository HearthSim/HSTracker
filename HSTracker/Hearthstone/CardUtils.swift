//
//  CardUtils.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardUtils {
    static func isCardFromPlayerClass(card: Card, playerClass: CardClass?, ignoreNeutral: Bool = false) -> Bool {
        guard let playerClass else {
            return false
        }
        return (card.isClass(cardClass: playerClass) || card.getTouristVisitClass() == playerClass ||
             (!ignoreNeutral && card.playerClass == .neutral))
    }

    static func mayCardBeRelevant(card: Card, gameType: GameType, format: FormatType, playerClass: CardClass?, ignoreNeutral: Bool = false) -> Bool {
        return card.isCardLegal(gameType: gameType, format: format) && isCardFromPlayerClass(card: card, playerClass: playerClass, ignoreNeutral: ignoreNeutral)
    }
    
    private static let _starshipIds = [
        CardIds.NonCollectible.Neutral.ArkoniteDefenseCrystal_TheExilesHopeToken,
        CardIds.NonCollectible.Deathknight.ArkoniteDefenseCrystal_TheSpiritsPassageToken,
        CardIds.NonCollectible.DemonHunter.ArkoniteDefenseCrystal_TheLegionsBaneToken,
        CardIds.NonCollectible.Druid.ArkoniteDefenseCrystal_TheCelestialArchiveToken,
        CardIds.NonCollectible.Hunter.ArkoniteDefenseCrystal_TheAstralCompassToken,
        CardIds.NonCollectible.Rogue.ArkoniteDefenseCrystal_TheScavengersWillToken,
        CardIds.NonCollectible.Warlock.ArkoniteDefenseCrystal_TheNethersEyeToken,
        CardIds.NonCollectible.Invalid.BattlecruiserToken
    ]

    public static func isStarship(_ cardId: String) -> Bool {
        return _starshipIds.contains(cardId)
    }
        
    static func getProcessedCardFromEntity(_ entity: Entity, _ player: Player) -> Card? {
        if isStarship(entity.cardId) {
            return entity.handleStarship(player)
        }
        let card = Cards.by(cardId: entity.cardId)
        return card?.handleZilliax3000(player: player)
    }
}

extension Entity {
    func handleStarship(_ player: Player) -> Card? {
        // Clone the card and get the starship pieces
        let card = card.copy()

        let starshipPieces = info.storedCardIds
            .compactMap { Cards.by(cardId: $0) }

        // Create a set of mechanics from all the starship pieces
        var mechanics = Set<String>()
        for piece in starshipPieces {
            for mechanic in piece.mechanics {
                mechanics.insert(mechanic)
            }
        }

        // Set the mechanics, stats, and cost
        card.mechanics = mechanics.compactMap { $0 }
        card.attack = starshipPieces.reduce(0, { $0 + $1.attack })
        card.health = starshipPieces.reduce(0, { $0 + $1.health })
        card.cost = max(10, starshipPieces.reduce(0, { $0 + $1.cost }))

        return card
    }
}

extension Card {
    func handleZilliax3000(player: Player) -> Card? {
        if id.starts(with: CardIds.Collectible.Neutral.ZilliaxDeluxe3000) {
            if let sideboard = player.playerSideboardsDict.first(where: { $0.ownerCardId == CardIds.Collectible.Neutral.ZilliaxDeluxe3000 }),
               sideboard.cards.count > 0 {
                let cosmetic = sideboard.cards.first { !$0.zilliaxCustomizableFunctionalModule }
                let modules = sideboard.cards.filter { $0.zilliaxCustomizableFunctionalModule }

                // Clone Zilliax with new cost, attack, health, and mechanics
                let newCard = cosmetic?.copy() ?? copy()
                var mechanics: [String] = []
                
                for module in modules where module.mechanics.count > 0 {
                    mechanics.append(contentsOf: module.mechanics)
                }
                
                newCard.mechanics = mechanics
                newCard.attack = modules.reduce(0) { $0 + $1.attack }
                newCard.health = modules.reduce(0) { $0 + $1.health }
                newCard.cost = modules.reduce(0) { $0 + $1.cost }
                
                return newCard
            }
        }
        
        return self
    }
    
    func hasDeathrattle() -> Bool {
        return mechanics.contains("DEATHRATTLE")
    }
    
    func hasTaunt() -> Bool {
        return mechanics.contains("TAUNT")
    }
}

extension Array where Element: Card {
    func filterCardsByFormat(gameType: GameType, format: FormatType) -> [Card] {
        return filter { $0.isCardLegal(gameType: gameType, format: format) }
    }
    
    func filterCardsByPlayerClass(playerClass: CardClass?, ignoreNeutral: Bool = false) -> [Card] {
        return filter { CardUtils.isCardFromPlayerClass(card: $0, playerClass: playerClass, ignoreNeutral: ignoreNeutral) }
    }
}
