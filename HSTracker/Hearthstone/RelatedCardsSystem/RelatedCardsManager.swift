//
//  RelatedCardsManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class RelatedCardsManager {
    private var relatedCards = [String: ICardWithRelatedCards]()
    private var highlightCards = [String: ICardWithHighlight]()
    
    private func initializeRelatedCards() {
        let _cards = ReflectionHelper.getRelatedClases()
        
        for card in _cards {
            let cardWithRelatedCards = card.init()
            relatedCards[cardWithRelatedCards.getCardId()] = cardWithRelatedCards
        }
    }
    
    private func initializeHighlightCards() {
        let _cards = ReflectionHelper.getHighlightClasses()
        
        for card in _cards {
            let cardWithHighlight = card.init()
            highlightCards[cardWithHighlight.getCardId()] = cardWithHighlight
        }
    }
    
    public func reset() {
        if relatedCards.count == 0 {
            initializeRelatedCards()
        }
        if highlightCards.count == 0 {
            initializeHighlightCards()
        }
    }
    
    public func getCardWithHighlight(_ cardId: String) -> ICardWithHighlight? {
        return highlightCards[cardId]
    }

    public func getCardWithRelatedCards(_ cardId: String) -> ICardWithRelatedCards? {
        return relatedCards[cardId]
    }
    
    public func getCardsOpponentMayHave(_ opponent: Player) -> [Card] {
        return relatedCards.values.filter { card in card.shouldShowForOpponent(opponent: opponent) }
            .compactMap { card in Cards.by(cardId: card.getCardId()) }
    }
}
