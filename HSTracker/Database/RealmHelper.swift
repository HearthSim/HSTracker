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
	
	// MARK: - Lifecycle
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
	
	// MARK: - Helper functions
	/*
	private static func runOnMain<T>(execute: @escaping () -> (T?) ) -> T? {
		var result: T?
		let mainSemaphore = DispatchSemaphore(value: 0)
		DispatchQueue.main.async { () in
			result = execute()
			mainSemaphore.signal()
		}
		mainSemaphore.wait()
		return result
	}
	
	private static func runOnMain<A, R>(execute: @escaping (A) -> (R?), param: A) -> R? {
		var result: R?
		let mainSemaphore = DispatchSemaphore(value: 0)

		DispatchQueue.main.async {
			result = execute(param)
			mainSemaphore.signal()
		}

		mainSemaphore.wait()
		return result
	}
	
	private static func runOnMain<A1, A2, R>(execute: @escaping (A1, A2) -> (R?), param1: A1, param2: A2) -> R? {
		var result: R?
		let mainSemaphore = DispatchSemaphore(value: 0)
		DispatchQueue.main.async { () in
			result = execute(param1, param2)
			mainSemaphore.signal()
		}
		mainSemaphore.wait()
		return result
	}*/
	
	// MARK: - Deck operations
	
	static func getDeck(with id: String) -> Deck? {
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return nil
		}
		
		return realm.objects(Deck.self).filter("deckId = '\(id)'").first
	}
	
	static func set(hsDeckId: Int64, for deckId: String) {
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return
		}
		
		if let _deck = realm.objects(Deck.self)
			.filter("deckId = '\(deckId)'").first {
			do {
				try realm.write {
					_deck.hsDeckId.value = hsDeckId
				}
			} catch {
				Log.error?.message("Can't update deck")
			}
		}
	}
    
    static func getDecks() -> [Deck]? {
        guard let realm = try? Realm() else {
            Log.error?.message("Error accessing Realm database")
            return nil
        }
        
        return Array(realm.objects(Deck.self))
    }
	
	static func getActiveDecks() -> [CardClass: [Deck]]? {
		
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
	
	/**
	* Checks if given deck exists in realm and returns it.
	*/
	static func checkAndUpdateDeck(deckId: Int64, selectedDeck: MirrorDeck?) -> Deck? {
		
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return nil
		}
		
		guard let storedDeck = realm.objects(Deck.self)
			.filter("hsDeckId = \(deckId)").first else {
				Log.error?.message("No realm deck found with \(deckId)")
				return nil
		}
		
		guard let selectedDeck = selectedDeck else { return storedDeck }
		
		// deck found, check if data needs to be updated
		let nameDoesNotMatch = storedDeck.name != selectedDeck.name
			|| storedDeck.heroId != selectedDeck.hero
		let cardsDontMatch = storedDeck.diffTo(mirrorDeck: selectedDeck)
		
		if nameDoesNotMatch || (cardsDontMatch.success && (cardsDontMatch.cards.count > 0)) {
			if nameDoesNotMatch {
				Log.info?.message("Deck \(selectedDeck.name) exists " +
					"with an old name (\(storedDeck.name)), updating it.")
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
							c.count = card.count as? Int ?? 0
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
	
	static func add(mirrorDeck: MirrorDeck, name: String? = nil, isArena: Bool = false) -> Deck? {
		
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return nil
		}
		
		let cards = mirrorDeck.cards
		
		guard let hero = Cards.hero(byId: mirrorDeck.hero as String) else {
			Log.error?.message("Mirrored deck has unknown hero id: \(mirrorDeck.hero)")
			return nil
		}
		
		let deck = Deck()
		if let name = name {
			deck.name = name
		} else {
			deck.name = mirrorDeck.name
		}
		deck.playerClass = hero.playerClass
		guard let hsDeckId = mirrorDeck.id as? Int64 else {
			Log.error?.message("Can not parse hs deck id")
			return nil
		}
		deck.hsDeckId.value = hsDeckId
		deck.isArena = isArena
		
		do {
			try realm.write {
				realm.add(deck)
				for card in cards {
					guard let c = Cards.by(cardId: card.cardId as String) else {
                        Log.error?.message("Unknown card id \(card.cardId as String)")
						continue
					}
					c.count = card.count as? Int ?? 0
					deck.add(card: c)
				}
			}
		} catch {
			Log.error?.message("Can not import deck. Error : \(error)")
			return nil
		}
		
		if deck.isValid() {
			Log.info?.message("Saving and using new deck : \(deck)")
		} else {
			Log.error?.message("Mirrored deck is not valid")
			return nil
		}
		
		NotificationCenter.default
			.post(name: Notification.Name(rawValue: "reload_decks"),
			      object: deck)
		
		return deck
	}
	
	static func checkOrCreateArenaDeck(mirrorDeck: MirrorDeck) -> Deck? {
		
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return nil
		}
        guard let hsDeckId = mirrorDeck.id as? Int64 else {
            Log.error?.message("Can not parse hs deck id")
            return nil
        }
		
		if let deck = realm.objects(Deck.self)
			.filter("hsDeckId = \(hsDeckId)").first {
			Log.info?.message("Arena deck \(hsDeckId) exists, using it.")
			return deck
		}
		
		Log.info?.message("Arena deck does not exists, creating it.")
		
		return RealmHelper.add(mirrorDeck: mirrorDeck, name: "Arena \(mirrorDeck.name)")
	}
	
	static func add(deck: Deck, update: Bool = false) {
        
        guard let realm = try? Realm() else {
            Log.error?.message("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                if update {
                    realm.add(deck, update: update)
                } else {
                    realm.add(deck)
                }
            }
        } catch {
            Log.error?.message("Can not add deck : \(error)")
        }
	}
	
	static func update(deck: Deck, with cards: [Card]) {
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				deck.cards.removeAll()
				for card in cards {
					deck.add(card: card)
				}
			}
		} catch {
			Log.error?.message("Can not add deck : \(error)")
		}
	}
	
	static func add(deck: Deck, with cards: [Card]) {
		
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				realm.add(deck)
				for card in cards {
					deck.add(card: card)
				}
			}
		} catch {
			Log.error?.message("Can not add deck : \(error)")
		}
	}
	
	static func delete(deck: Deck) {
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				realm.delete(deck)
			}
		} catch {
			Log.error?.message("Can not delete deck : \(error)")
		}
	}
	
	// MARK: - Deck properties
	
	static func set(deck: Deck, active: Bool) {
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				deck.isActive = active
			}
		} catch {
			Log.error?.message("Can't set deck as active : \(error)")
		}
	}
    
    static func rename(deck: Deck, to name: String) {
        guard let realm = try? Realm() else {
            Log.error?.message("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                deck.name = name
            }
        } catch {
            Log.error?.message("Can not rename deck. \(error)")
        }
    }
	
	// MARK: - Statistics
	
	static func getValidStatistics() -> Results<GameStats>? {
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return nil
		}
		
		return realm.objects(GameStats.self)
			.filter("hsReplayId != nil")
			.sorted(byKeyPath: "startTime", ascending: false)
	}
	
	static func addStatistics(to deck: Deck, stats: GameStats) {
		guard let realm = try? Realm() else {
			Log.error?.message("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				deck.gameStats.append(stats)
			}
		} catch {
			Log.error?.message("Can't save statistic : \(error)")
		}
	}
    
    static func removeAllGameStats(from deck: Deck) {
        guard let realm = try? Realm() else {
            Log.error?.message("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                deck.gameStats.removeAll()
            }
        } catch {
            Log.error?.message("Can't save statistic : \(error)")
        }
    }
    
    static func getGameStat(with statId: String) -> GameStats? {
        guard let realm = try? Realm() else {
            Log.error?.message("Error accessing Realm database")
            return nil
        }
        
        return realm.objects(GameStats.self)
            .filter("statId = '\(statId)'").first
    }
    
    static func update(stat: GameStats, hsReplayId: String) {
        guard let realm = try? Realm() else {
            Log.error?.message("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                stat.hsReplayId = hsReplayId
            }
        } catch {
            Log.error?.message("Can not update statistic")
        }
        
    }
}
