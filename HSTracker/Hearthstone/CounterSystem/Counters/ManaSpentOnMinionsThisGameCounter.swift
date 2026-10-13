//
//  ManaSpentOnMinionsThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Y'Shaarj, Titan Bane: "Old God. Battlecry: If you've spent 30 Mana on minions this game, gain Immune for 1 turn."
class ManaSpentOnMinionsThisGameCounter: NumericCounter {
    private static let yshaarjThreshold = 30

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.YshaarjTitanBane
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.YshaarjTitanBane
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 20 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter
            ? getCardsInDeckOrKnown(cardIds: relatedCards)
            : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        let threshold = ManaSpentOnMinionsThisGameCounter.yshaarjThreshold
        return "\(min(counter, threshold))/\(threshold)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag != .num_resources_spent_this_game {
            return
        }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        guard let block = AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock,
              block.type == "PLAY" else {
            return
        }

        guard let playedCard = Cards.by(cardId: block.cardId ?? ""), playedCard.type == .minion else {
            return
        }

        let spent = value - prevValue
        if spent <= 0 {
            return
        }

        counter += spent
    }
}
