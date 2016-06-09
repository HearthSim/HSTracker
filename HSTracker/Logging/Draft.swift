//
//  Draft.swift
//  HSTracker
//
//  Created by Jon Nguy on 6/8/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class Draft {
    // MARK: - vars
    var deck: Deck?
    
    var drafting = false
    
    static let instance = Draft()
    init() {
        
    }
    
    init(playerClass: String) {
        startDraft(playerClass)
    }
    
    func resetDraft() {
        Log.verbose?.message("Resetting draft")
        
        drafting = false
        deck?.reset()
    }
    
    func startDraft(playerClass: String) {
        // If we're already drafting and we start, we need to reset
        if drafting {
            Log.debug?.message("We're trying to start a draft when we " +
                "already had one started. Starting a new one.")
            resetDraft()
            return
        }
        drafting = true
        deck = Deck(playerClass: playerClass)
    }
    
    func addCard(card: Card) {
        deck?.addCard(card)
        
        if deck?.countCards() == 30 {
            NSNotificationCenter.defaultCenter()
                .postNotification(NSNotification(name: "arena_deck_full", object: nil))
            
        }
    }
    
}