//
//  HSTLogListener.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 Benjamin Michotte. All rights reserved.
//

import Foundation
import kotlin_hslog

class HSTLogListener: HSLogListener {
    let windowManager: WindowManager
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }
    
    func onDeckEntries(game: kotlin_hslog.Game, isPlayer: Bool, deckEntries: [DeckEntry]) {
        let heroes = deckEntries.filter {
            $0 is DeckEntry.Hero
        }
        // swiftlint:disable force_cast
        windowManager.battlegroundsOverlay.setHeroes(heroes: heroes as! [DeckEntry.Hero])
        // swiftlint:enable force_cast
    }
    
    func onDeckFound(deck: kotlin_hslog.Deck, deckString: String, isArena: Bool) {
        
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
    
    func onCardGained(cardGained: AchievementsParser.CardGained) {
        
    }

    func onRawGame(gameString: KotlinByteArray, gameStartMillis: Int64) {
        
    }
    
    func onSecrets(possibleSecrets: [PossibleSecret]) {
        
    }
}
