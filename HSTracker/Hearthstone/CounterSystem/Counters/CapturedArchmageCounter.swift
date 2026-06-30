//
//  CapturedArchmageCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class CapturedArchmageCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.CapturedArchmage
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Neutral.CapturedArchmage]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard game.isMulliganDone() else { return }
        guard entity.cardId == CardIds.Collectible.Neutral.CapturedArchmage else { return }
        guard tag == .zone else { return }
        
        // Check if the entity moved explicitly from PLAY to GRAVEYARD
        guard prevValue == Zone.play.rawValue else { return }
        guard value == Zone.graveyard.rawValue else { return }

        let controller = entity[.controller]
        let isPlayerController = controller == game.player.id
        
        if (isPlayerController && isPlayerCounter) || (!isPlayerController && !isPlayerCounter) {
            counter += 1
        }
    }
}
