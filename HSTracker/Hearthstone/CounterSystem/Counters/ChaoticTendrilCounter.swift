//
//  ChaoticTendrilCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ChaoticTendrilCounter: NumericCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.ChaoticTendril
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.ChaoticTendril
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCards)
        } else {
            return counter > 0 && opponentMayHaveRelevantCards()
        }
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(min(counter + 1, 10))"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard tag == .zone && AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" else { return }

        let isCurrentController = isPlayerCounter ? entity.isControlled(by: game.player.id) : entity.isControlled(by: game.opponent.id)

        guard isCurrentController && entity.card.id == CardIds.Collectible.Neutral.ChaoticTendril else { return }

        counter += 1
    }
}
