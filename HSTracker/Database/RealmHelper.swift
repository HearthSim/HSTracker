//
//  RealmHandler.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 22/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import CleanroomLogger
import HearthMirror

/**
 * Handles all database releated actions
 */
struct RealmHelper {
	
	static func getDeck(with id: String) -> Deck?  {
		return DispatchQueue.main.sync { () -> Deck? in
			guard let realm = try? Realm() else {
				Log.error?.message("Error accessing Realm database")
				return nil
			}
			
			return realm.objects(Deck.self).filter("deckId = '\(id)'").first
		}
	}
	
	/**
	 * Checks if given deck exists in realm and returns it.
	 */
	static func checkAndUpdateDeck(deckId: Int64, selectedDeck: MirrorDeck?) -> Deck? {
		
		return DispatchQueue.main.sync { () -> Deck? in
			guard let realm = try? Realm() else {
				Log.error?.message("Error accessing Realm database")
				return nil
			}
			
			guard let storedDeck = realm.objects(Deck.self)
				.filter("hsDeckId = \(deckId)").first else {
					return nil
			}
			
			guard let selectedDeck = selectedDeck else { return storedDeck }
			
			// deck found, check if data needs to be updated
			let nameDoesNotMatch = storedDeck.name != selectedDeck.name
				|| storedDeck.heroId != selectedDeck.hero
			let cardsDontMatch = storedDeck.diffTo(mirrorDeck: selectedDeck)
			
			if nameDoesNotMatch || (cardsDontMatch.success && (cardsDontMatch.cards.count > 0)) {
				if nameDoesNotMatch {
					Log.info?.message("Deck \(selectedDeck.name) exists" +
						"with an old name, updating it.")
				} else {
					Log.info?.message("Deck \(selectedDeck.name) exists, updating it.")
				}
				
				do {
					try realm.write {
						if nameDoesNotMatch {
							storedDeck.name = selectedDeck.name
							storedDeck.heroId = selectedDeck.hero
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
						}
					}
				} catch {
					Log.error?.message("Can not import deck. Error : \(error)")
				}
				if storedDeck.isValid() {
					return storedDeck
				}
				Log.error?.message("Mirrored deck is not valid")
				return nil
			} else {
				Log.info?.message("Deck \(selectedDeck.name) exists, using it.")
				return storedDeck
			}
		}
	}
	
	static func checkOrCreateArenaDeck(mirrorDeck: MirrorDeck) -> Deck? {
		
		return DispatchQueue.main.sync { () -> Deck? in
			guard let realm = try? Realm() else {
				Log.error?.message("Error accessing Realm database")
				return nil
			}
			let hsDeckId = mirrorDeck.id as Int64
			
			if let deck = realm.objects(Deck.self)
				.filter("hsDeckId = \(hsDeckId)").first {
				Log.info?.message("Arena deck \(hsDeckId) exists, using it.")
				return deck
			}
			
			Log.info?.message("Arena deck does not exists, creating it.")
			let cards = mirrorDeck.cards
			
			guard let hero = Cards.hero(byId: mirrorDeck.hero as String) else {
				Log.error?.message("Mirrored arena deck has unknown hero id: \(mirrorDeck.hero)")
				return nil
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
				}
			} catch {
				Log.error?.message("Can not import deck. Error : \(error)")
				return nil
			}
			if deck.isValid() {
				Log.info?.message("Saving and using new arena deck : \(deck)")
				NotificationCenter.default
					.post(name: Notification.Name(rawValue: "reload_decks"),
					      object: deck)
				return deck
			} else {
				Log.error?.message("Mirrored arena deck is not valid")
				return nil
			}
			
		}
	}
	
	
}
