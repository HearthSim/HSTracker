//
//  HSTLogListener.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 Benjamin Michotte. All rights reserved.
//

import Foundation

class HSTLogListener: HSLogListener {
    private let windowManager: WindowManager
    private let toaster: Toaster
    var currentDeck: kotlin_hslog.Deck?
    var currentDeckIsArena = false
    
    init(windowManager: WindowManager, toaster: Toaster) {
        self.windowManager = windowManager
        self.toaster = toaster
    }

    func bgHeroesShow(game: kotlin_hslog.Game, entities: [kotlin_hslog.Entity]) {
    }
    
    func onCardGained(cardGained: CardGained) {
        
    }
   
    func bgHeroesHide() {
    }
            
    func onDeckEntries(game: kotlin_hslog.Game, isPlayer: Bool, deckEntries: [DeckEntry]) {
    }
    
    func onDeckFound(deck: kotlin_hslog.Deck, deckString: String, isArena: Bool) {
        FreezeHelperKt.freeze(deck)
        currentDeck = deck
        currentDeckIsArena = isArena
    }
    
    func onGameChanged(game: kotlin_hslog.Game) {
        
    }
    
    func onGameEnd(game: kotlin_hslog.Game) {
        
    }
    
    func onGameStart(game: kotlin_hslog.Game) {
    }
    
    func onOpponentDeckChanged(deck: kotlin_hslog.Deck) {
        
    }
    
    func onPlayerDeckChanged(deck: kotlin_hslog.Deck) {
        
    }
    
    func onTurn(game: kotlin_hslog.Game, turn: Int32, isPlayer: Bool) {
        
    }

    func onRawGame(gameString: KotlinByteArray, gameStartMillis: Int64) {
        
    }
    
    func onSecrets(possibleSecrets: [PossibleSecret]) {
        
    }
}
