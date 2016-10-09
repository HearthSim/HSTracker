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
    
    static let token: dispatch_once_t = 0
    
    static let instance = Draft()
    
    init() {
    }
    
    init(playerClass: CardClass) {
        startDraft(playerClass)
    }
    
    func resetDraft() {
        Log.verbose?.message("Resetting draft")
        
        drafting = false
        deck?.reset()
    }
    
    func startDraft(playerClass: CardClass) {
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
    
    func addCard(card: Card) {
        deck?.addCard(card)
        
        if let deck = deck where deck.isValid() {
            dispatch_async(dispatch_get_main_queue()) {
                let alert = NSAlert()
                alert.alertStyle = .Informational
                // swiftlint:disable line_length
                alert.messageText = NSLocalizedString("Your arena deck count 30 cards, do you want to save it ?",
                                                      comment: "")
                // swiftlint:enable line_length
                alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
                NSRunningApplication.currentApplication().activateWithOptions([
                    NSApplicationActivationOptions.ActivateAllWindows,
                    NSApplicationActivationOptions.ActivateIgnoringOtherApps])
                NSApp.activateIgnoringOtherApps(true)
                if alert.runModal() == NSAlertFirstButtonReturn {
                    NSNotificationCenter.defaultCenter().postNotificationName("save_arena_deck",
                                                                              object: nil)
                }
            }
        }
    }
    
}
