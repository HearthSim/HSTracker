//
//  FullScreenFxHandler.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift

struct FullScreenFxHandler {

    let BeginBlurRegex = "BeginEffect blur \\d => 1"
    
    private var lastQueueTime: Date = Date.distantPast
    
    mutating func handle(game: Game, logLine: LogLine) {
        guard let currentMode = game.currentMode else {
            return
        }

        let modes: [Mode] = [.tavern_brawl, .tournament, .draft, .friendly, .adventure]
        if logLine.line.match(BeginBlurRegex) && game.isInMenu && modes.contains(currentMode) {
            game.enqueueTime = logLine.time
            Log.info?.message("now in queue (\(logLine.time))")
            if abs(logLine.time.timeIntervalSinceNow) > 5
                || !game.isInMenu || logLine.time <= lastQueueTime {
                return
            }
            lastQueueTime = logLine.time

            guard Settings.autoDeckDetection else {
                return
            }

            let selectedModes: [Mode] = [.tavern_brawl, .tournament,
                                         .friendly, .adventure]
            if selectedModes.contains(currentMode) {
                autoSelectDeckById(game: game, mode: currentMode)
            } else if currentMode == .draft {
                autoSelectArenaDeck(game: game)
            }
        }
    }

    private func autoSelectDeckById(game: Game, mode: Mode) {
        guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
              let mirror = hearthstone.mirror else {
            return
        }

        Log.info?.message("Trying to import deck from Hearthstone")

        var selectedDeckId: Int64 = 0
        if let selectedId = mirror.getSelectedDeck() as? Int64 {
            selectedDeckId = selectedId
        } else {
            selectedDeckId = hearthstone.deckWatcher.selectedDeckId
        }

        if selectedDeckId <= 0 {
            if mode != .tavern_brawl {
                game.set(activeDeck: nil)
                return
            }
        }

        let decks = mirror.getDecks()
        guard let selectedDeck = decks.first({ $0.id as Int64 == selectedDeckId }) else {
            Log.warning?.message("No deck with id=\(selectedDeckId) found")
            game.set(activeDeck: nil)
            return
        }
        Log.info?.message("Found selected deck : \(selectedDeck.name)")

        guard let realm = try? Realm() else {
            return
        }

        if let storedDeck = realm.objects(Deck.self)
                .filter("hsDeckId = \(selectedDeckId)").first {

            // deck found, check if data needs to be updated
            let nameDoesNotMatch = storedDeck.name != selectedDeck.name
            let cardsDontMatch = storedDeck.diffTo(mirrorDeck: selectedDeck)
            if nameDoesNotMatch || (cardsDontMatch.success && (cardsDontMatch.cards.count > 0)) {
                if nameDoesNotMatch {
                    Log.info?.message("Deck \(selectedDeck.name) exists" +
                            "with an old name, updating and using it.")
                } else {
                    Log.info?.message("Deck \(selectedDeck.name) exists, updating and using it.")
                }
                do {
                    try realm.write {
                        if nameDoesNotMatch {
                            storedDeck.name = selectedDeck.name
                        }

                        let numDifferentCards: Int = cardsDontMatch.cards.reduce(0, {
                            $0 + $1.count
                        })
                        if cardsDontMatch.success && numDifferentCards > 0 {
                            storedDeck.cards.removeAll()
                            let cards = selectedDeck.cards
                            for card in cards {
                                guard let c = Cards.by(cardId: card.cardId as String)
                                        else {
                                    continue
                                }
                                c.count = card.count as Int
                                storedDeck.add(card: c)
                            }

                            // swapping 4 different cards yields to major update
                            if cardsDontMatch.cards.count > 4 {
                                storedDeck.incrementVersion(major: 1)
                            } else {
                                storedDeck.incrementVersion(minor: 1)
                            }

                            if storedDeck.isValid() {
                                Log.info?.message("Saving and using deck : \(storedDeck)")
                                let deckId = storedDeck.deckId
                                game.set(activeDeck: deckId)
                                return
                            }
                        }
                    }
                } catch {
                    Log.error?.message("Can not import deck. Error : \(error)")
                }
            } else {
                Log.info?.message("Deck \(selectedDeck.name) exists, using it.")

                let deckId = storedDeck.deckId
                game.set(activeDeck: deckId)
                return
            }

        } else {
            Log.info?.message("Deck \(selectedDeck.name) does not exists, creating it.")

            guard let hero = Cards.hero(byId: selectedDeck.hero as String) else {
                return
            }
            let deck = Deck()
            deck.name = selectedDeck.name as String
            deck.playerClass = hero.playerClass
            deck.hsDeckId.value = selectedDeckId

            let cards = selectedDeck.cards
            do {
                try realm.write {
                    realm.add(deck)
                    for card in cards {
                        guard let c = Cards.by(cardId: card.cardId as String) else {
                            continue
                        }
                        c.count = card.count as Int
                        deck.add(card: c)
                    }
                    if deck.isValid() {
                        Log.info?.message("Saving and using deck : \(deck)")
                        let deckId = deck.deckId
                        game.set(activeDeck: deckId)
                        NotificationCenter.default
                            .post(name: Notification.Name(rawValue: "reload_decks"),
                                  object: deck)
                    }
                }
            } catch {
                Log.error?.message("Can not import deck. Error : \(error)")
            }
        }

    }

    private func autoSelectArenaDeck(game: Game) {
        guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
              let mirror = hearthstone.mirror else {
            return
        }
        Log.info?.message("Trying to import arena deck from Hearthstone")

        var hsMirrorDeck: MirrorDeck?
        if let mDeck = mirror.getArenaDeck()?.deck {
            hsMirrorDeck = mDeck
        } else {
            hsMirrorDeck = hearthstone.arenaDeckWatcher.selectedDeck
        }
        
        guard let hsDeck = hsMirrorDeck else {
            Log.warning?.message("Can't get arena deck")
            game.set(activeDeck: nil)
            return
        }

        guard let realm = try? Realm() else {
            return
        }
        let hsDeckId = hsDeck.id as Int64

        if let deck = realm.objects(Deck.self)
                .filter("hsDeckId = \(hsDeckId)").first {
            Log.info?.message("Arena deck \(hsDeckId) exists, using it.")
            let deckId = deck.deckId
            game.set(activeDeck: deckId)
            return
        }

        Log.info?.message("Arena deck does not exists, creating it.")
        let cards = hsDeck.cards

        guard let hero = Cards.hero(byId: hsDeck.hero as String) else {
            return
        }
        let deck = Deck()
        deck.name = "Arena \(hero.name)"
        deck.playerClass = hero.playerClass
        deck.hsDeckId.value = hsDeckId
        deck.isArena = true

        do {
            try realm.write {
                realm.add(deck)
                for card in cards {
                    guard let c = Cards.by(cardId: card.cardId as String) else {
                        continue
                    }
                    c.count = card.count as Int
                    deck.add(card: c)
                }
                if deck.isValid() {
                    Log.info?.message("Saving and using deck : \(deck)")
                    let deckId = deck.deckId
                    NotificationCenter.default
                        .post(name: Notification.Name(rawValue: "reload_decks"),
                              object: deck)
                    game.set(activeDeck: deckId)
                }
            }
        } catch {
            Log.error?.message("Can not import deck. Error : \(error)")
        }
    }
}
