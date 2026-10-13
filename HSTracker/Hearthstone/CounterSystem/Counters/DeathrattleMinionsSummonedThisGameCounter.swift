//
//  DeathrattleMinionsSummonedThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// N'Zoth, Dream's End: "Old God. Costs (1) less for each Deathrattle minion you've summoned this game."
class DeathrattleMinionsSummonedThisGameCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_SummonedDeathrattleMinions", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.NzothDreamsEnd
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.NzothDreamsEnd
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
        return counter > 4 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter
            ? getCardsInDeckOrKnown(cardIds: relatedCards)
            : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if tag != .zone || value != Zone.play.rawValue {
            return
        }

        if !entity.isMinion {
            return
        }

        if !entity.has(tag: .deathrattle) && !entity.latestCard.hasDeathrattle() {
            return
        }

        counter += 1
    }
}
