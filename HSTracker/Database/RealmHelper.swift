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
	
	/** 
		Initializes the realm database. Calls migration if current database's version differs from the latest one
	*/
	static func initRealm(destination: URL) {
		let config = Realm.Configuration(
			fileURL: destination.appendingPathComponent("hstracker.realm"),
			schemaVersion: 5,
			migrationBlock: { migration, oldSchemaVersion in
				// version == 1 : add hearthstoneId in Deck,
				// automatically managed by realm, nothing to do here
				
				if oldSchemaVersion < 2 {
					migration.enumerateObjects(ofType:
					Deck.className()) { oldObject, newObject in
						// version == 2 : hearthstoneId is now hsDeckId,
						if let hearthstoneId = oldObject?["hearthstoneId"] as? Int {
							newObject!["hsDeckId"] = Int64(hearthstoneId)
						}
					}
				}
				
				if oldSchemaVersion < 4 {
					// deck.version changes from string to two ints (major, minor)
					migration.enumerateObjects(ofType:
					Deck.className()) { oldObject, newObject in
						if let versionStr = oldObject?["version"] as? String {
							if let ver = Double(versionStr) {
								let majorVersion = Int(ver)
								let minorVersion = Int((ver - Double(majorVersion)) * 10.0)
								newObject!["deckMajorVersion"] = majorVersion
								newObject!["deckMinorVersion"] = minorVersion
							} else {
								newObject!["deckMajorVersion"] = 1
								newObject!["deckMinorVersion"] = 0
							}
						}
					}
				}
		})
		Realm.Configuration.defaultConfiguration = config
	}
	
	static func getDeck(with id: String) -> Deck? {
		return DispatchQueue.main.sync { () -> Deck? in
			guard let realm = try? Realm() else {
				Log.error?.message("Error accessing Realm database")
				return nil
			}
			
			return realm.objects(Deck.self).filter("deckId = '\(id)'").first
		}
	}
	
	static func getActiveDecks() -> [CardClass: [Deck]]? {
		
		return DispatchQueue.main.sync { () -> [CardClass: [Deck]]? in
			guard let realm = try? Realm() else {
				Log.error?.message("Can not fetch decks")
				return nil
			}
			
			var decks: [CardClass: [Deck]] = [:]
			for deck in realm.objects(Deck.self).filter("isActive = true") {
				if decks[deck.playerClass] == nil {
					decks[deck.playerClass] = [Deck]()
				}
				decks[deck.playerClass]?.append(deck)
			}
			return decks
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
	
	static func addDeck(deck: Deck) {
		return DispatchQueue.main.sync { () in
			
			guard let realm = try? Realm() else {
				Log.error?.message("Error accessing Realm database")
				return
			}
			
			do {
				try realm.write {
					realm.add(deck)
				}
			} catch {
				Log.error?.message("Can not create deck")
			}
		}
	}
	
	static func getValidStatistics() -> Results<GameStats>? {
		
		return DispatchQueue.main.sync { () -> Results<GameStats>? in
			
			guard let realm = try? Realm() else {
				Log.error?.message("Error accessing Realm database")
				return nil
			}
			
			return realm.objects(GameStats.self)
				.filter("hsReplayId != nil")
				.sorted(byKeyPath: "startTime", ascending: false)
		}
	}
	
}
