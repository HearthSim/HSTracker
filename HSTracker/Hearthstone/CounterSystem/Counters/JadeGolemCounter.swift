//
//  JadeGolemCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class JadeGolemCounter: NumericCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.JadeGolem1
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Druid.JadeIdol,
            CardIds.Collectible.Druid.JadeBlossom,
            CardIds.Collectible.Druid.JadeBehemoth,
            CardIds.Collectible.Druid.JadeBehemothWONDERS,
            CardIds.Collectible.Rogue.JadeSwarmer,
            CardIds.Collectible.Rogue.JadeSwarmerWONDERS,
            CardIds.Collectible.Rogue.JadeTelegram,
            CardIds.Collectible.Rogue.JadeShuriken,
            CardIds.Collectible.Rogue.JadeShurikenWONDERS,
            CardIds.Collectible.Shaman.JadeClaws,
            CardIds.Collectible.Shaman.JadeLightning,
            CardIds.Collectible.Shaman.JadeLightningWONDERS,
            CardIds.Collectible.Shaman.JadeChieftain,
            CardIds.Collectible.Shaman.JadeChieftainWONDERS,
            CardIds.Collectible.Neutral.JadeSpirit,
            CardIds.Collectible.Neutral.JadeSpiritWONDERS,
            CardIds.Collectible.Neutral.AyaBlackpaw,
            CardIds.Collectible.Neutral.AyaBlackpawWONDERS
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return [CardIds.NonCollectible.Neutral.JadeGolem1]
    }

    override func valueToShow() -> String {
        let jadeSize = min(counter + 1, 30)
        return "\(jadeSize)/\(jadeSize)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag == .jade_golem, entity[.cardtype] == CardType.player.rawValue && value > 0 {
            let controller = entity[.controller]
            if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
                counter = value
            }
        }
    }
}
