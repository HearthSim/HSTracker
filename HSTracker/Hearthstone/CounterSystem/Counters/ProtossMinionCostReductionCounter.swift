//
//  ProtossMinionCostReductionCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ProtossMinionCostReductionCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_ProtossMinionCostReduction", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Invalid.PhotonCannon
    }
    
    private lazy var _protossMinions: [String] = Cards.collectible().filter({ c in c.faction == .protoss }).compactMap({ c in c.id })

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Priest.Sentry,
            CardIds.Collectible.Invalid.PhotonCannon,
            CardIds.Collectible.Invalid.Artanis
        ]
    }

    private static let artanisDbfId: Int = {
        if let artanis = Cards.any(byId: CardIds.Collectible.Invalid.Artanis) {
            return artanis.dbfId
        }
        return -1
    }()

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: _protossMinions)
        }
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        }
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch,
              tag == .zone,
              value == Zone.play.rawValue,
              entity.card.id == CardIds.NonCollectible.Neutral.ConstructPylons_PsionicPowerEnchantment else {
            return
        }

        // Artanis discounts by 2
        let amount = entity[.creator_dbid] == ProtossMinionCostReductionCounter.artanisDbfId ? 2 : 1
        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter += amount
        }
    }
}
