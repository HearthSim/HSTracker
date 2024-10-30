//
//  ElementalTurnSequenceCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ElementalTurnSequenceCounter: NumericCounter {
    
    override var localizedName: String {
        return String.localizedString("Counter_ElementalTurnSequence", comment: "")
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.AzeriteGiant
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.Lamplighter,
            CardIds.Collectible.Neutral.AzeriteGiant,
            CardIds.Collectible.Mage.ElementalAllies,
            CardIds.Collectible.Mage.OverflowSurger,
            CardIds.Collectible.Shaman.SkarrTheCatastrophe
        ]
    }

    private var shownBefore: Bool = false
    private var lastPlayedTurn: Int = 0
    private var playedThisTurn: Bool = false

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        } else if counter > 2 && opponentMayHaveRelevantCards() {
            shownBefore = true
        }
        
        return (counter > 2 && opponentMayHaveRelevantCards()) || shownBefore
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ? getCardsInDeckOrKnown(cardIds: relatedCards) : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.playerClass)
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    func handleElementalPlayed(game: Game, entity: Entity) {
        guard game.isTraditionalHearthstoneMatch else { return }

        let isCurrentController = isPlayerCounter ? entity.isControlled(by: game.player.id) : entity.isControlled(by: game.opponent.id)
        guard isCurrentController, entity.card.isElemental(), !playedThisTurn else { return }

        let turnNumber = game.turnNumber()
        if turnNumber == lastPlayedTurn + 1 || counter == 0 {
            lastPlayedTurn = turnNumber
            playedThisTurn = true
            counter += 1
        }
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag == .zone, AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" {
            handleElementalPlayed(game: game, entity: entity)
        }
        
        guard tag == .current_player else { return }
        
        let isNewEnemyTurn = isPlayerCounter ? game.opponentEntity?.has(tag: .current_player) ?? false : game.playerEntity?.has(tag: .current_player) ?? false
        let isNewFriendlyTurn = isPlayerCounter ? game.playerEntity?.has(tag: .current_player) ?? false : game.opponentEntity?.has(tag: .current_player) ?? false

        if isNewFriendlyTurn {
            playedThisTurn = false
        } else if isNewEnemyTurn, !playedThisTurn {
            counter = 0
        }
    }
}
