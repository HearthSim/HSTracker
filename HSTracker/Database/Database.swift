//
//  Database.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MagicalRecord

class Database {
    let DatabaseVersion = 1

    func loadDatabaseIfNeeded(splashscreen: Splashscreen) {
        let dbVersion = Settings.instance.databaseVersion
        if dbVersion < DatabaseVersion {
            DDLogVerbose("Database already on version \(DatabaseVersion)")
            return
        }

        // start by truncating everything
        Card.MR_truncateAll()
        CardMechanic.MR_truncateAll()

        var langs: [String] = ["enUS"]
        if let language = Settings.instance.hearthstoneLanguage where language != "enUS" {
            langs += [language]
        }

        let validCardSet: [String] = ["CORE", "EXPERT1", "NAXX", "GVG", "BRM", "TGT", "LOE", "PROMO", "REWARD"]
        for lang in langs {
            let jsonFile = NSBundle.mainBundle().resourcePath! + "cardsDB.\(lang).json"
            DDLogVerbose("json file : \(jsonFile)")
            let jsonData = NSData(contentsOfFile: jsonFile)

            do {
                let cards: [[String:AnyObject]] = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: .AllowFragments) as! [[String:AnyObject]]

                dispatch_async(dispatch_get_main_queue()) {
                    splashscreen.display("Loading \(lang) cards", total: Double(cards.count))
                }

                for jsonCard in cards {
                    dispatch_async(dispatch_get_main_queue()) {
                        splashscreen.increment()
                    }

                    let set = jsonCard["set"] as! String
                    if !validCardSet.contains(set) {
                        continue
                    }

                    MagicalRecord.saveWithBlockAndWait({
                        (localContext) -> Void in
                        let card = Card.MR_createEntityInContext(localContext)!
                        card.cardId = jsonCard["id"] as! String
                        card.lang = lang

                        // "fake" the coin... in the game files, Coin cost is empty
                        // so we set it to 0
                        if card.cardId == "GAME_005" {
                            card.cost = 0
                        } else {
                            card.cost = jsonCard["cost"] as! Int
                        }

                        if let cardRarity = jsonCard["rarity"] as? String {
                            card.rarity = cardRarity.lowercaseString
                        }

                        if let cardType = jsonCard["type"] as? String {
                            card.type = cardType.lowercaseString
                        }

                        if let cardPlayerClass = jsonCard["playerClass"] as? String {
                            card.playerClass = cardPlayerClass.lowercaseString
                        }

                        if let cardFaction = jsonCard["faction"] as? String {
                            card.faction = cardFaction.lowercaseString
                        }

                        card.set = set.lowercaseString
                        card.health = jsonCard["health"] as! Int
                        card.flavor = jsonCard["flavor"] as! String
                        card.collectible = jsonCard["collectible"] != nil
                        card.name = jsonCard["name"] as! String
                        card.text = jsonCard["text"] as! String

                        if let mechanics = jsonCard["mechanics"] as? [String] {
                            for mechanic in mechanics {
                                let _mechanic = mechanic.lowercaseString
                                var cardMechanic = CardMechanic.MR_findFirstByAttribute("name", withValue: _mechanic)
                                if cardMechanic == nil {
                                    cardMechanic = CardMechanic.MR_createEntityInContext(localContext)
                                    cardMechanic!.name = _mechanic
                                }
                                card.mechanics.insert(cardMechanic!)
                            }
                        }
                    })

                }
            } catch {
                print(error)
            }
        }
        Settings.instance.databaseVersion = DatabaseVersion
    }
}