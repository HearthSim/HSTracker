//
//  Database.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Database {
    static let currentSeason: Int = {
        let today = Date()
        let dc = Calendar.current.dateComponents(in: TimeZone.current, from: today)
        return (dc.year! - 2014) * 12 - 3 + dc.month!
    }()

    static func jsonFilesAreValid() -> Bool {
        for locale in Language.Hearthstone.cases() {

            let jsonFile = Paths.cardJson.appendingPathComponent("cardsDB.\(locale.rawValue).json")
            guard let jsonData = try? Data(contentsOf: jsonFile) else {
                logger.error("\(jsonFile) is not a valid file")
                return false
            }
            if (try? JSONSerialization
                .jsonObject(with: jsonData, options: []) as? [[String: Any]]) == nil {
                    logger.error("\(jsonFile) is not a valid file")
                    return false
            }
        }
        return true
    }
    
    static let validCardSets = CardSet.cases()

    static let deckManagerCardTypes = ["all_types", "spell", "minion", "weapon"]
    static var deckManagerRaces = [Race]()

    func loadDatabase(splashscreen: Splashscreen?, withLanguages langs: [Language.Hearthstone]) {
        for lang in langs {
            let file = Bundle(for: type(of: self))
                .url(forResource: "Resources/Cards/cardsDB.\(lang.rawValue)",
                    withExtension: "json")

            guard let jsonFile = file else {
                logger.error("Can't find cardsDB.\(lang.rawValue).json")
                continue
            }

            logger.verbose("json file : \(jsonFile)")

            guard let jsonData = try? Data(contentsOf: jsonFile) else {
                logger.error("\(jsonFile) is not a valid file")
                continue
            }
            guard let jsonCards = try? JSONSerialization
                    .jsonObject(with: jsonData, options: []) as? [[String: Any]],
                let cards = jsonCards else {
                                    logger.error("\(jsonFile) is not a valid file")
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

                guard let cardId = jsonCard["id"] as? String,
                    let jsonSet = jsonCard["set"] as? String,
                    let set = CardSet(rawValue: jsonSet.lowercased()),
                    Database.validCardSets.contains(set) else { continue }

                if let name = jsonCard["name"] as? String,
                    let card = Cards.cards.first(where: { $0.id == cardId }),
                    lang == .enUS && langs.count > 1 {
                    card.enName = name
                } else {
                    let card = Card()
                    card.jsonRepresentation = jsonCard
                    card.id = cardId
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

                    if let cardClass = jsonCard["cardClass"] as? String,
                        let cardPlayerClass = CardClass(rawValue: cardClass.lowercased()) {
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
