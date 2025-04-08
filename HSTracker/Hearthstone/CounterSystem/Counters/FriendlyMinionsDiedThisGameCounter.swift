//
//  FriendlyMinionsDiedThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FriendlyMinionsDiedThisGameCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_FriendlyMinionsDiedThisGame", comment: "")
    }

    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Mage.Aessina
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Mage.Aessina,
            CardIds.Collectible.Mage.Starsurge
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        let couldBeGenerated = game.opponent.playerEntities.contains { entity in
            guard entity.isInHand || entity.isInPlay || entity.isInDeck else { return false }
            guard entity.info.created else { return false }
            guard entity.hasCardId && entity.cardId == CardIds.Collectible.Mage.Aessina else { return false }
            
            let creatorId = entity.info.getCreatorId()
            guard creatorId > 0, let creator = game.entities[creatorId] else { return false }
            
            return creator.cardId == CardIds.Collectible.Neutral.MalorneTheWaywatcher
        }

        return (opponentMayHaveRelevantCards() && counter >= 10) || couldBeGenerated
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        }

        let cardsFilteredByClassAndFormat = filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        return cardsFilteredByClassAndFormat.isEmpty ? [CardIds.Collectible.Mage.Aessina] : cardsFilteredByClassAndFormat
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard game.isMulliganDone() else { return }
        guard entity.isMinion else { return }
        guard tag == .zone else { return }
        guard prevValue == Zone.play.rawValue else { return }
        guard value == Zone.graveyard.rawValue else { return }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) ||
           (controller == game.opponent.id && !isPlayerCounter) {
            counter += 1
        }
    }
}
