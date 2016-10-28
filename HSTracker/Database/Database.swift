//
//  Database.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct Database {
    static let currentSeason: Int = {
        let date = Date()
        return (date.year - 2014) * 12 - 3 + date.month
    }()
    
    static let validCardSets = CardSet.allValues()

    static let deckManagerCardTypes = ["all_types", "spell", "minion", "weapon"]
    static var deckManagerRaces = [Race]()

    // swiftlint:disable line_length
    func loadDatabase(splashscreen: Splashscreen?) -> [String]? {
        var imageLanguage = "enUS"
        var langs: [String] = []
        if let language = Settings.instance.hearthstoneLanguage, language != "enUS" {
            langs += [language]
            imageLanguage = language
        }
        langs += ["enUS"]

        var images = [String]()
        guard let destination = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory,
            .userDomainMask, true).first else {
                Log.error?.message("Can't get HSTracker path")
                return nil
        }

        for lang in langs {
            let jsonFile = "\(destination)/HSTracker/json/cardsDB.\(lang).json"
            Log.verbose?.message("json file : \(jsonFile)")
            if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonFile)) {
                do {
                    if let cards: [[String: AnyObject]]
                        = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [[String: AnyObject]] {

                    if let splashscreen = splashscreen {
                        DispatchQueue.main.async {
                            splashscreen.display(String(format: NSLocalizedString("Loading %@ cards", comment: ""), lang), total: Double(cards.count))
                        }
                    }

                    for jsonCard in cards {
                        if let splashscreen = splashscreen {
                            DispatchQueue.main.async {
                                splashscreen.increment()
                            }
                        }

                        if let jsonSet = jsonCard["set"] as? String,
                            let set = CardSet(rawValue: jsonSet.lowercased()) {
                        if !Database.validCardSets.contains(set) {
                            continue
                        }

                        if let cardId = jsonCard["id"] as? String {

                            if lang == "enUS" && langs.count > 1 {
                                if let card = Cards.cards.firstWhere({ $0.id == cardId }) {
                                    if let name = jsonCard["name"] as? String {
                                        card.enName = name
                                    }
                                }
                            } else {
                                let card = Card()
                                card.id = cardId

                                card.isStandard = !CardSet.wildSets().contains(set)

                                // "fake" the coin... in the game files, Coin cost is empty
                                // so we set it to 0
                                if card.id == "GAME_005" {
                                    card.cost = 0
                                    images.append(card.id)
                                } else {
                                    if let cost = jsonCard["cost"] as? Int {
                                        card.cost = cost
                                    }
                                }

                                if let cardRarity = jsonCard["rarity"] as? String,
                                    let rarity = Rarity(rawValue: cardRarity.lowercased()) {
                                    card.rarity = rarity
                                }

                                if let type = jsonCard["type"] as? String,
                                    let cardType = CardType(rawString: type.lowercased()) {
                                    card.type = cardType
                                }

                                if let playerClass = jsonCard["playerClass"] as? String,
                                    let cardPlayerClass = CardClass(rawValue: playerClass.lowercased()) {
                                    card.playerClass = cardPlayerClass
                                }

                                if let faction = jsonCard["faction"] as? String,
                                    let cardFaction = Faction(rawValue: faction.lowercased()) {
                                    card.faction = cardFaction
                                }

                                card.set = set
                                if let health = jsonCard["health"] as? Int {
                                    card.health = health
                                }
                                if let attack = jsonCard["attack"] as? Int {
                                    card.attack = attack
                                }
                                if let race = jsonCard["race"] as? String,
                                    let cardRace = Race(rawValue: race.lowercased()) {
                                    card.race = cardRace
                                    if !Database.deckManagerRaces.contains(cardRace) {
                                        Database.deckManagerRaces.append(cardRace)
                                    }
                                }
                                if let flavor = jsonCard["flavor"] as? String {
                                    card.flavor = flavor
                                }
                                if let collectible = jsonCard["collectible"] as? Bool {
                                    card.collectible = collectible

                                    // card is collectible, mark it as needed for download
                                    if lang == imageLanguage && card.type != .hero {
                                        images.append(card.id)
                                    }
                                }
                                if let name = jsonCard["name"] as? String {
                                    card.name = name
                                }
                                if let text = jsonCard["text"] as? String {
                                    card.text = text
                                }
                                if let artist = jsonCard["artist"] as? String {
                                    card.artist = artist
                                }
                                Cards.cards.append(card)
                                /*if let mechanics = jsonCard["mechanics"] as? [String] {
                                 for mechanic in mechanics {
                                 let _mechanic = mechanic.lowercaseString
                                 var cardMechanic = CardMechanic.MR_findFirstByAttribute("name", withValue: _mechanic, inContext: localContext)
                                 if cardMechanic == nil {
                                 cardMechanic = CardMechanic.MR_createEntityInContext(localContext)
                                 cardMechanic!.name = _mechanic
                                 }
                                 card.mechanics.insert(cardMechanic!)
                                 }
                                 }*/
                            }
                        }
                        }
                    }
                    }
                } catch {
                    print(error)
                }
            } else {
                // TODO show error
            }
        }
        return images
    }
    // swiftlint:enable line_length
}
