//
//  Database.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class Database {
    static let currentSeason: Int = {
        let today = Date()
        let dc = Calendar.current.dateComponents(in: TimeZone.current, from: today)
        return (dc.year! - 2014) * 12 - 3 + dc.month!
    }()

    static func jsonFilesAreValid() -> Bool {
        for locale in Language.Hearthstone.allValues() {

            let jsonFile = Paths.cardJson.appendingPathComponent("cardsDB.\(locale.rawValue).json")
            guard let jsonData = try? Data(contentsOf: jsonFile) else {
                Log.error?.message("\(jsonFile) is not a valid file")
                return false
            }
            guard let _ = try? JSONSerialization
                .jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    Log.error?.message("\(jsonFile) is not a valid file")
                    return false
            }
        }
        return true
    }
    
    static let validCardSets = CardSet.allValues()

    static let deckManagerCardTypes = ["all_types", "spell", "minion", "weapon"]
    static var deckManagerRaces = [Race]()

    func loadDatabase(splashscreen: Splashscreen?, withLanguages langs: [Language.Hearthstone]) {
        for lang in langs {
            //var file: URL? = Paths.cardJson.appendingPathComponent("cardsDB.\(lang.rawValue).json")
            
            //if file == nil || (file != nil && !FileManager.default.fileExists(atPath: file!.path)) {
                let file = Bundle(for: type(of: self))
                    .url(forResource: "Resources/Cards/cardsDB.\(lang.rawValue)",
                        withExtension: "json")
            //}
            guard let jsonFile = file else {
                Log.error?.message("Can't find cardsDB.\(lang.rawValue).json")
                continue
            }

            Log.verbose?.message("json file : \(jsonFile)")

            guard let jsonData = try? Data(contentsOf: jsonFile) else {
                Log.error?.message("\(jsonFile) is not a valid file")
                continue
            }
            guard let jsonCards = try? JSONSerialization
                    .jsonObject(with: jsonData, options: []) as? [[String: Any]],
                let cards = jsonCards else {
                                    Log.error?.message("\(jsonFile) is not a valid file")
                continue
            }

            if let splashscreen = splashscreen {
                DispatchQueue.main.async {
                    let msg = String(format: NSLocalizedString("Loading %@ cards",
                                                               comment: ""), lang.localizedString)
                    splashscreen.display(msg, total: Double(cards.count))
                }
            }

            for jsonCard: [String: Any] in cards {
                if let splashscreen = splashscreen {
                    DispatchQueue.main.async {
                        splashscreen.increment()
                    }
                }

                guard let cardId = jsonCard["id"] as? String else { continue }
                guard let jsonSet = jsonCard["set"] as? String,
                    let set = CardSet(rawValue: jsonSet.lowercased()) else { continue }
                guard Database.validCardSets.contains(set) else { continue }

                if let name = jsonCard["name"] as? String,
                    let card = Cards.cards.first({ $0.id == cardId }),
                    lang == .enUS && langs.count > 1 {
                    card.enName = name
                } else {
                    let card = Card()
                    card.jsonRepresentation = jsonCard
                    card.id = cardId
                    if let dbfId = jsonCard["dbfId"] as? Int {
                        card.dbfId = dbfId
                    }

                    if let dbfId = jsonCard["dbfId"] as? Int {
                        card.dbfId = dbfId
                    }

                    card.isStandard = !CardSet.wildSets().contains(set)

                    if let cost = jsonCard["cost"] as? Int {
                        card.cost = cost
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
                    if let durability = jsonCard["durability"] as? Int {
                        card.durability = durability
                    }
                    if let overload = jsonCard["overload"] as? Int {
                        card.overload = overload
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
                    }
                    if let name = jsonCard["name"] as? String {
                        card.name = name
                        if lang == .enUS && langs.count == 1 {
                            card.enName = name
                        }
                    }
                    if let text = jsonCard["text"] as? String {
                        card.text = text
                    }
                    if let artist = jsonCard["artist"] as? String {
                        card.artist = artist
                    }
                    if let mechanics = jsonCard["mechanics"] as? [String] {
                        for mechanic in mechanics {
                            let cardMechanic = CardMechanic(name: mechanic)
                            card.mechanics.append(cardMechanic)
                        }
                    }
                    Cards.cards.append(card)
                }
            }
        }
    }
}
