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
        deck = nil
    }
    
    init(playerClass: String) {
        startDraft(playerClass)
    }
    
    func resetDraft() {
        Log.verbose?.message("Resetting draft")
        
        deck?.reset()
    }
    
    func startDraft(playerClass: String) {
        if drafting {
            return
        }
        drafting = true
        deck = Deck(playerClass: playerClass)
    }
    
    func addCard(card: Card) {
        deck?.addCard(card)
    }
    
}