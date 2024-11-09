//
//  SelfDamageCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SelfDamageCounter: NumericCounter {
    
    override var localizedName: String {
        return String.localizedString("Counter_SelfDamage", comment: "")
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Warlock.PartyPlannerVona
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Warlock.PartyPlannerVona,
            CardIds.Collectible.Warlock.ImprisonedHorror
        ]
    }
    
    private var preDamage: Int = 0
    
    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 7 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        }
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if !entity.isHero { return }
        
        let isEnemyTurn = (isPlayerCounter ? game.opponentEntity?.has(tag: .current_player) : game.playerEntity?.has(tag: .current_player)) ?? false
        let isFriendlyTurn = (isPlayerCounter ? game.playerEntity?.has(tag: .current_player) : game.opponentEntity?.has(tag: .current_player)) ?? false

        if isEnemyTurn { return }
        if !isFriendlyTurn { return }

        if !isPlayerCounter && entity[.controller] == game.player.id { return }
        if isPlayerCounter && entity[.controller] == game.opponent.id { return }

        if tag == .predamage {
            if value == 0 || prevValue != 0 { return }
            preDamage = value
            return
        }
        
        if tag == .damage {
            if preDamage + prevValue != value { return }
            counter += preDamage
            preDamage = 0
        }
    }
}
