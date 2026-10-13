//
//  BloodRunesPlayedCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// G'huun: "Battlecry: Steal 6 Health split among the lowest Health enemies. Improved by Blood Runes you've played."
class BloodRunesPlayedCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_BloodRunesPlayed", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Deathknight.Ghuun
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Deathknight.Ghuun
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
        return counter > 5 && opponentMayHaveRelevantCards()
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

        if tag != .zone {
            return
        }

        if value != Zone.play.rawValue && value != Zone.secret.rawValue {
            return
        }

        if AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type != "PLAY" {
            return
        }

        let bloodRunes = entity.latestCard.costBlood
        if bloodRunes <= 0 {
            return
        }

        counter += bloodRunes
    }
}
