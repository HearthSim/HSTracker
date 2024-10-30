//
//  PogoHopperCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PogoHopperCounter: NumericCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Rogue.PogoHopper
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Rogue.PogoHopper
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
        let pogoSize = counter * 2 + 1
        return "\(pogoSize)/\(pogoSize)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard tag == .zone && AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" else { return }

        let isCurrentController = isPlayerCounter ? entity.isControlled(by: game.player.id) : entity.isControlled(by: game.opponent.id)

        guard isCurrentController && entity.card.id == CardIds.Collectible.Rogue.PogoHopper else { return }

        counter += 1
    }
}
