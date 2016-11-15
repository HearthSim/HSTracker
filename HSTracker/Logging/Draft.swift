//
//  Draft.swift
//  HSTracker
//
//  Created by Jon Nguy on 6/8/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift

class Draft {
    // MARK: - vars
    var playerClass: CardClass?
    var cards: [Card]?
    var hearthstoneId: Int?
    
    var drafting = false
    
    static let instance = Draft()
    
    func resetDraft() {
        Log.verbose?.message("Resetting draft")
        
        drafting = false
        playerClass = nil
        cards = nil
    }
    
    func startDraft(for playerClass: CardClass) {
        // If we're already drafting and we start, we need to reset
        if drafting {
            Log.debug?.message("We're trying to start a draft when we " +
                "already had one started. Starting a new one.")
            resetDraft()
        }
        drafting = true
        Log.debug?.message("Starting a new deck for \(playerClass)")
        self.playerClass = playerClass
        self.cards = []
    }
    
    func add(card: Card) {
        guard drafting else { return }

        card.count = 1
        cards?.append(card)
        Log.info?.message("Adding card \(card)")

        // Check if that draft already exists
        if let realm = try? Realm(), let id = hearthstoneId {
            if let _ = realm.objects(Deck.self).filter("hearthstoneId = \(id)").first {
                Log.debug?.message("Arena deck \(id) already exists, skip")
                return
            }
        }

        if let _ = playerClass, let cards = cards, cards.isValidDeck() {
            DispatchQueue.main.async {
                let msg = "Your arena deck count 30 cards, do you want to save it ?"
                if NSAlert.show(style: .informational,
                             message: NSLocalizedString(msg, comment: ""),
                             forceFront: true) {
                    NotificationCenter.default
                        .post(name: Notification.Name(rawValue: "save_arena_deck"),
                              object: nil)
                }
            }
        }
    }
    
}
