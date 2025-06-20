//
//  RealmHandler.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 22/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import HearthMirror

/**
* Handles all database releated actions
*/
struct RealmHelper {
    
    static let dungeonRunDeckId = "DungeonRunDeck"
	
	// MARK: - Lifecycle
	/**
	Initializes the realm database. Calls migration if current database's version differs from the latest one
	*/
	static func initRealm(destination: URL) {
		let config = Realm.Configuration(
			fileURL: destination.appendingPathComponent("hstracker.realm"),
			schemaVersion: 8,
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
                
                if oldSchemaVersion < 6 {
                    migration.enumerateObjects(ofType: Deck.className()) { _, newObject in
                        newObject!["isDungeon"] = false
                        newObject!["isDuels"] = false
                    }
                }
                if oldSchemaVersion < 7 {
                    migration.enumerateObjects(ofType: Deck.className()) { _, newObject in
                        newObject!["lastEdited"] = Date()
                    }
                }
		})
		Realm.Configuration.defaultConfiguration = config
	}
	
	// MARK: - Deck operations
	
	static func getDeck(with id: String) -> Deck? {
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return nil
		}
		
		if let deck = realm.objects(Deck.self).filter("deckId = '\(id)'").first {
			RealmHelper.validateCardCounts(deck)
			return deck
		}
		return nil
	}
	
	static func validateCardCounts(_ deck: Deck) {
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				for card in deck.cards where card.count > 30 {
                    card.count = 1
				}
			}
		} catch {
			logger.error("Can't update deck")
		}
	}
	
	static func set(hsDeckId: Int64, for deckId: String) {
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return
		}
		
		if let _deck = realm.objects(Deck.self)
			.filter("deckId = '\(deckId)'").first {
			do {
				try realm.write {
					_deck.hsDeckId.value = hsDeckId
				}
			} catch {
				logger.error("Can't update deck")
			}
		}
	}
    
    static func getDecks() -> [Deck]? {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return nil
        }
		
		let decks = Array(realm.objects(Deck.self))
		
		for deck in decks {
			RealmHelper.validateCardCounts(deck)
		}
		return decks
    }
	
	static func getActiveDecks() -> [CardClass: [Deck]]? {
		
		guard let realm = try? Realm() else {
			logger.error("Can not fetch decks")
			return nil
		}
		
		var decks: [CardClass: [Deck]] = [:]
		for deck in realm.objects(Deck.self).filter("isActive = true") {
			if decks[deck.playerClass] == nil {
				decks[deck.playerClass] = [Deck]()
			}
			RealmHelper.validateCardCounts(deck)
			decks[deck.playerClass]?.append(deck)
		}
		return decks
	}
    
    static func checkAndUpdateDungeonRunDeck(cards: [Card], reset: Bool = false) -> Deck? {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return nil
        }
        
        if let deck = realm.objects(Deck.self)
            .filter("deckId = \"\(RealmHelper.dungeonRunDeckId)\"").first {
            // Deck exists, update it
            update(deck: deck, with: cards, resetStats: reset)
            return deck
        }
        
        // Add new deck
        let deck = Deck()
        deck.deckId = RealmHelper.dungeonRunDeckId
        add(deck: deck, with: cards)
        return deck
    }
	
	/**
	* Checks if given deck exists in realm and returns it.
	*/
	static func checkAndUpdateDeck(deckId: Int64, selectedDeck: MirrorDeck?) -> Deck? {
		
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return nil
		}
		
		guard let storedDeck = realm.objects(Deck.self)
			.filter("hsDeckId = \(deckId)").first else {
				logger.error("No realm deck found with \(deckId)")
				return nil
		}
		
		guard let selectedDeck = selectedDeck else { return storedDeck }
		
		// deck found, check if data needs to be updated
		let nameDoesNotMatch = storedDeck.name != selectedDeck.name
			|| storedDeck.heroId != selectedDeck.hero
        let cardsDontMatch = storedDeck.diff(newDeck: selectedDeck)
        let sideboardsDontMatch = storedDeck.sideboardDiff(newDeck: selectedDeck)
		
        if nameDoesNotMatch || cardsDontMatch.count > 0 || sideboardsDontMatch.count > 0 {
			if nameDoesNotMatch {
				logger.info("Deck \(selectedDeck.name) exists " +
					"with an old name (\(storedDeck.name)), updating it.")
			} else {
				logger.info("Deck \(selectedDeck.name) exists, updating it.")
			}
			
			do {
                try realm.write {
                    if nameDoesNotMatch {
                        storedDeck.name = selectedDeck.name
                        storedDeck.heroId = selectedDeck.hero
                    }
                    
                    var numDifferentCards: Int = cardsDontMatch.reduce(0, {
                        $0 + $1.count
                    })
                    if numDifferentCards > 0 {
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
                        if cardsDontMatch.count > 4 {
                            storedDeck.incrementVersion(major: 1)
                        } else {
                            storedDeck.incrementVersion(minor: 1)
                        }
                    }
                    numDifferentCards = sideboardsDontMatch.reduce(0, {
                        $0 + $1.count
                    })
                    if numDifferentCards > 0 {
                        storedDeck.sideboards.removeAll()
                        for sideboard in selectedDeck.sideboards {
                            let owner = sideboard.key
                            let s = RealmSideboard(ownerCardId: owner)
                            //                            realm.add(s)
                            for card in sideboard.value {
                                s.add(card: Card(fromMirrorCard: card))
                            }
                            storedDeck.sideboards.append(s)
                        }
                    }
                }
			} catch {
				logger.error("Can not import deck. Error : \(error)")
			}
			if storedDeck.isValid() {
				return storedDeck
			}
			logger.error("Mirrored deck is not valid")
			return nil
		} else {
			logger.info("Deck \(selectedDeck.name) exists, using it.")
			return storedDeck
		}
	}
	
	static func add(mirrorDeck: MirrorDeck, name: String? = nil, isArena: Bool = false) -> Deck? {
		
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return nil
		}
		
		let cards = mirrorDeck.cards
		
		guard let hero = Cards.hero(byId: mirrorDeck.hero as String) else {
			logger.error("Mirrored deck has unknown hero id: \(mirrorDeck.hero)")
			return nil
		}
		
		let deck = Deck()
		if let name = name {
			deck.name = name
		} else {
			deck.name = mirrorDeck.name
		}
		deck.playerClass = hero.playerClass
		deck.heroId = mirrorDeck.hero
		guard let hsDeckId = mirrorDeck.id as? Int64 else {
			logger.error("Can not parse hs deck id")
			return nil
		}
		deck.hsDeckId.value = hsDeckId
		deck.isArena = isArena
		
		do {
			try realm.write {
				realm.add(deck)
				for card in cards {
					guard let c = Cards.by(cardId: card.cardId as String) else {
                        logger.error("Unknown card id \(card.cardId as String)")
						continue
					}
					c.count = card.count as? Int ?? 0
					deck.add(card: c)
				}
			}
		} catch {
			logger.error("Can not import deck. Error : \(error)")
			return nil
		}
		
		if deck.isValid() {
			logger.info("Saving and using new deck : \(deck)")
		} else {
			logger.error("Mirrored deck is not valid")
			return nil
		}
		
		NotificationCenter.default
			.post(name: Notification.Name(rawValue: Events.reload_decks),
			      object: deck)
		
		return deck
	}
	
    static func autoImportArena(_ info: MirrorArenaInfo? = nil) -> Deck? {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return nil
        }

        guard let deck = info ?? DeckImporter.fromArena(), deck.deck.cards.reduce(into: 0, { $0 += $1.count.intValue }) == 30 else {
            return nil
        }
        
        logger.info("Found new complete \(deck.deck.hero) arena deck!")
        
        if let matchingHsId = realm.objects(Deck.self).filter("hsDeckId = \(deck.deck.id)").first, matchingHsId.isArena {
            // update NOOOOOO! cards after expansion release
            logger.info("...but we already know that id. Checking for changes...")

            if matchingHsId.cards.allSatisfy({ c in deck.deck.cards.any({ c2 in c.id == c2.cardId && c.count == c2.count.intValue })}) {
                logger.info("No changes found")
                return matchingHsId
            }
            
            logger.info("Updating deck with new cards...")
            do {
                try realm.write {
                    matchingHsId.cards.removeAll()
                    let cards: [Card] = deck.deck.cards.compactMap({ x in
                        guard let card = Cards.by(cardId: x.cardId) else {
                            return nil
                        }
                        card.count = x.count.intValue
                        return card
                    })
                    for card in cards {
                        matchingHsId.add(card: card)
                    }
                    
//                    DeckList.Instance.ActiveDeck = matchingHsId
                    // setting current deck will happen via caller
                    return matchingHsId
                }
            } catch {
                logger.error("Can not import deck. Error : \(error)")
            }
            return nil
        }
        
        return importArenaDeck(deck.deck)
    }
    
    static func importArenaDeck(_ deck: MirrorDeck) -> Deck? {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return nil
        }
        
        let hero = Cards.any(byId: deck.hero)
        let arenaDeck = Deck()
        arenaDeck.playerClass = hero?.playerClass ?? .neutral
        arenaDeck.heroId = deck.hero
        arenaDeck.hsDeckId.value = deck.id.int64Value
        arenaDeck.isArena = true
        arenaDeck.name = Helper.parseDeckNameTemplate(template: Settings.importArenaDeckNameTemplate, deck: arenaDeck)
        
        logger.info("Saving new arena deck: \(arenaDeck.name) (\(arenaDeck.hsDeckId.value ?? -1))")
        
        do {
            try realm.write {
                realm.add(arenaDeck)
                for card in deck.cards.compactMap({ c in
                    if let res = Cards.any(byId: c.cardId) {
                        res.count = c.count.intValue
                        return res
                    }
                    return nil
                }) {
                    arenaDeck.add(card: card)
                }
            }
            return arenaDeck
        } catch {
            logger.error("Can not import deck. Error : \(error)")
        }
        return nil
    }
    	
	static func add(deck: Deck, update: Bool = false) {
        
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                Influx.breadcrumb(eventName: "realm_add_deck", withProperties: ["name": deck.name, "id": deck.deckId])
                if update {
                    realm.add(deck, update: .all)
                } else {
                    realm.add(deck)
                }
            }
        } catch {
            logger.error("Can not add deck : \(error)")
        }
	}
	
    static func update(deck: Deck, with cards: [Card], resetStats: Bool = false) {
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
                Influx.breadcrumb(eventName: "realm_update_deck", withProperties: ["name": deck.name, "id": deck.deckId])
				deck.cards.removeAll()
				for card in cards {
					deck.add(card: card)
				}
                if resetStats {
                    deck.gameStats.removeAll()
                }
                deck.lastEdited = Date()
			}
		} catch {
			logger.error("Can not add deck : \(error)")
		}
	}
	
	static func add(deck: Deck, with cards: [Card]) {
		
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
                Influx.breadcrumb(eventName: "realm_add_deck_with_cards", withProperties: ["name": deck.name, "id": deck.deckId])
				realm.add(deck)
				for card in cards {
					deck.add(card: card)
				}
			}
		} catch {
			logger.error("Can not add deck : \(error)")
		}
	}
	
	static func delete(deck: Deck) {
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
                Influx.breadcrumb(eventName: "realm_delete_deck", withProperties: ["name": deck.name, "id": deck.deckId])
				realm.delete(deck)
			}
		} catch {
			logger.error("Can not delete deck : \(error)")
		}
	}
	
	// MARK: - Deck properties
	
	static func set(deck: Deck, active: Bool) {
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				deck.isActive = active
			}
		} catch {
			logger.error("Can't set deck as active : \(error)")
		}
	}
    
    static func rename(deck: Deck, to name: String) {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                Influx.breadcrumb(eventName: "realm_rename_deck", withProperties: ["name": deck.name, "id": deck.deckId, "newName": name])
                deck.name = name
            }
        } catch {
            logger.error("Can not rename deck. \(error)")
        }
    }
	
	// MARK: - Statistics
	
	static func getValidStatistics() -> [GameStats]? {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return nil
        }
        var results = [GameStats]()
        for deck in realm.objects(Deck.self) {
            for stat in deck.gameStats where stat.hsReplayId != nil {
                results.append(stat)
            }
        }
        return results.sorted(by: { $0.startTime > $1.startTime })
	}
	
	static func addStatistics(to deck: Deck, stats: GameStats) {
		guard let realm = try? Realm() else {
			logger.error("Error accessing Realm database")
			return
		}
		
		do {
			try realm.write {
				deck.gameStats.append(stats)
			}
		} catch {
			logger.error("Can't save statistic : \(error)")
		}
	}
    
    static func removeAllGameStats(from deck: Deck) {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                deck.gameStats.removeAll()
            }
        } catch {
            logger.error("Can't save statistic : \(error)")
        }
    }
    
    static func getGameStat(deckId: Int64, with statId: String) -> GameStats? {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return nil
        }
        
        return realm.objects(Deck.self)
            .filter("hsDeckId = \(deckId)").first?.gameStats.first { x in x.statId == statId }
    }
    
    static func update(stat: GameStats, hsReplayId: String) {
        guard let realm = try? Realm() else {
            logger.error("Error accessing Realm database")
            return
        }
        
        do {
            try realm.write {
                stat.hsReplayId = hsReplayId
            }
        } catch {
            logger.error("Can not update statistic")
        }
        
    }
}
