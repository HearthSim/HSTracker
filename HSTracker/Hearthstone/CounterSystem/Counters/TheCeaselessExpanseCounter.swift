//
//  TheCeaselessExpanseCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

class TheCeaselessExpanseCounter: NumericCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.TheCeaselessExpanse
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.TheCeaselessExpanse
        ]
    }
    
    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }
    
    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return !inPlayerDeckOrKnown(cardIds: relatedCards) && counter >= 50 && opponentMayHaveRelevantCards()
    }
    
    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ?
        getCardsInDeckOrKnown(cardIds: relatedCards) :
        filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }
    
    override func valueToShow() -> String {
        return String(counter)
    }
    
    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isTraditionalHearthstoneMatch {
            return
        }

        if !game.isMulliganDone() {
            return
        }

        if tag != GameTag.zone {
            return
        }

        switch prevValue {
        case Zone.deck.rawValue where value == Zone.hand.rawValue:
            counter += 1
            return
        case Zone.hand.rawValue where value == Zone.play.rawValue:
            counter += 1
            return
        case Zone.hand.rawValue where value == Zone.secret.rawValue:
            counter += 1
            return
        case Zone.play.rawValue where value == Zone.graveyard.rawValue && (entity.isMinion || entity.isWeapon || entity.isLocation):
            counter += 1
            return
        case Zone.deck.rawValue where value == Zone.graveyard.rawValue && entity.info.guessedCardState != .none:
            counter += 1
            return
        default:
            return
        }
    }
}
