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
    private var spellSchoolTutorCards = [String: ISpellSchoolTutor]()
    
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
    
    private func initializeSpellSchoolTutorCards() {
        let _cards = ReflectionHelper.getSpellSchoolTutorClasses()
        
        for card in _cards {
            let cardWithSpellSchoolTutor = card.init()
            spellSchoolTutorCards[cardWithSpellSchoolTutor.getCardId()] = cardWithSpellSchoolTutor
        }
    }
    
    public func reset() {
        if relatedCards.count == 0 {
            initializeRelatedCards()
        }
        if highlightCards.count == 0 {
            initializeHighlightCards()
        }
        if spellSchoolTutorCards.count == 0 {
            initializeSpellSchoolTutorCards()
        }
    }
    
    public func getCardWithHighlight(_ cardId: String) -> ICardWithHighlight? {
        return highlightCards[cardId]
    }

    public func getCardWithRelatedCards(_ cardId: String) -> ICardWithRelatedCards? {
        return relatedCards[cardId]
    }
    
    public func getSpellSchoolTutor(_ cardId: String) -> ISpellSchoolTutor? {
        return spellSchoolTutorCards[cardId]
    }
    
    public func getCardsOpponentMayHave(_ opponent: Player, _ gameType: GameType, _ format: FormatType) -> [Card] {
        return relatedCards.values.filter { card in card.shouldShowForOpponent(opponent: opponent) && card.isCardLegal(gameType: gameType, format: format) }
            .compactMap { card in Cards.by(cardId: card.getCardId()) }
    }
}
