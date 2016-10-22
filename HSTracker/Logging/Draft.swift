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
    
    static let token: Int = 0
    
    static let instance = Draft()
    
    init() {
    }
    
    init(playerClass: CardClass) {
        startDraft(for: playerClass)
    }
    
    func resetDraft() {
        Log.verbose?.message("Resetting draft")
        
        drafting = false
        deck?.reset()
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
        deck = Deck(playerClass: playerClass)
    }
    
    func add(card: Card) {
        deck?.add(card: card)
        
        if let deck = deck, deck.isValid() {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .informational
                // swiftlint:disable line_length
                alert.messageText = NSLocalizedString("Your arena deck count 30 cards, do you want to save it ?",
                                                      comment: "")
                // swiftlint:enable line_length
                alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                NSRunningApplication.current().activate(options: [
                    NSApplicationActivationOptions.activateAllWindows,
                    NSApplicationActivationOptions.activateIgnoringOtherApps])
                NSApp.activate(ignoringOtherApps: true)
                if alert.runModal() == NSAlertFirstButtonReturn {
                    NotificationCenter.default
                        .post(name: Notification.Name(rawValue: "save_arena_deck"),
                              object: nil)
                }
            }
        }
    }
    
}
