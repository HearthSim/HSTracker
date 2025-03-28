//
//  File.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class AnachronosTurnCounter: NumericCounter {
    
    // Properties
    public var anachronosEnchantmentsInPlay: Int = 0
    private var anachronosPowerBlockId: Int = -1
    private var opponentMinions: [String] = []
    private var playerMinions: [String] = []
    
    private var opponentHero: String {
        return game.opponentHeroId
    }
    
    private var playerHero: String {
        return game.playerHeroId
    }
    
    // Override properties
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Paladin.Anachronos
    }
    
    override var relatedCards: [String] {
        return []
    }
    
    // Initializer
    public required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }
    
    // Private Methods
    private func cards() -> [String] {
        var result: [String] = []
        if !opponentMinions.isEmpty {
            result.append(contentsOf: opponentMinions)
            result.append(opponentHero)
        }
        if !playerMinions.isEmpty {
            result.append(contentsOf: playerMinions)
            result.append(playerHero)
        }
        return result
    }
    
    // Override Methods
    override func shouldShow() -> Bool {
        return game.isTraditionalHearthstoneMatch && anachronosEnchantmentsInPlay > 0
    }
    
    override func getCardsToDisplay() -> [String] {
        var result: [String] = []
        if !opponentMinions.isEmpty {
            result.append(opponentHero)
            result.append(contentsOf: opponentMinions)
        }
        if !playerMinions.isEmpty {
            result.append(playerHero)
            result.append(contentsOf: playerMinions)
        }
        return result
    }
    
    override func valueToShow() -> String {
        return "\(counter) / 2"
    }
    
    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if tag == GameTag.zone,
           entity.cardId == CardIds.NonCollectible.Paladin.Anachronos_TimeTravelEnchantment,
           entity[GameTag.controller] == (isPlayerCounter ? game.player.id :game.opponent.id) {
            
            if value == Zone.play.rawValue {
                anachronosEnchantmentsInPlay += 1
                counter = 0
                onCounterChanged()
                
                if anachronosPowerBlockId == -1 {
                    anachronosPowerBlockId = AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.id ?? -1
                }
            } else if value == Zone.graveyard.rawValue {
                anachronosEnchantmentsInPlay -= 1
                onCounterChanged()
                anachronosPowerBlockId = -1
                playerMinions.removeAll()
                opponentMinions.removeAll()
            }
        }
        
        if anachronosEnchantmentsInPlay >= 2 { return }
        handleMinions(tag: tag, entity: entity, value: value, prevValue: prevValue)
        
        guard entity.cardId == CardIds.NonCollectible.Paladin.Anachronos_TimeTravelEnchantment,
              tag == GameTag.tag_script_data_num_2 else { return }
        
        let controller = entity[GameTag.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter = value
        }
    }
    
    private func handleMinions(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.id == anachronosPowerBlockId,
              entity.isMinion,
              tag == GameTag.zone,
              prevValue == Zone.play.rawValue,
              value == Zone.setaside.rawValue
        else { return }
        
        let cardId = entity.cardId
        let controller = entity[GameTag.controller]
        if controller == game.player.id {
            playerMinions.append(cardId)
            onCounterChanged()
        } else if controller == game.opponent.id {
            opponentMinions.append(cardId)
            onCounterChanged()
        }
    }
}
