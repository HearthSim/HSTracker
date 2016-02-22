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

    func loadDatabaseIfNeeded(splashscreen: Splashscreen) -> [String]? {
        let dbVersion = Settings.instance.databaseVersion
        if dbVersion >= DatabaseVersion {
            DDLogVerbose("Database already on version \(DatabaseVersion)")
            return nil
        }

        // start by truncating everything
        Card.MR_truncateAll()
        CardMechanic.MR_truncateAll()

        var imageLanguage = "enUS"
        var langs = [String]()
        if let language = Settings.instance.hearthstoneLanguage where language != "enUS" {
            langs += [language]
            imageLanguage = language
        }
        langs += ["enUS"]
        
        var images = [String]()

        let validCardSet: [String] = ["CORE", "EXPERT1", "NAXX", "GVG", "BRM", "TGT", "LOE", "PROMO", "REWARD"]
        for lang in langs {
            let jsonFile = NSBundle.mainBundle().resourcePath! + "/Resources/Cards/cardsDB.\(lang).json"
            DDLogVerbose("json file : \(jsonFile)")
            if let jsonData = NSData(contentsOfFile: jsonFile) {
                do {
                    let cards: [[String:AnyObject]] = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as! [[String:AnyObject]]

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

                        MagicalRecord.saveWithBlockAndWait({ (localContext) -> Void in
                            if let cardId = jsonCard["id"] as? String {
                                
                                if lang == "enUS" {
                                    if let card = Card.MR_findFirstByAttribute("cardId", withValue: cardId, inContext: localContext) {
                                        if let name = jsonCard["name"] as? String {
                                            card.enName = name
                                        }
                                    }
                                }
                                else {
                                    let card = Card.MR_createEntityInContext(localContext)!
                                    card.cardId = cardId
                                    
                                    // future work ;)
                                    card.isStandard = false
                                    
                                    // "fake" the coin... in the game files, Coin cost is empty
                                    // so we set it to 0
                                    if card.cardId == "GAME_005" {
                                        card.cost = 0
                                    } else {
                                        if let cost = jsonCard["cost"] as? Int {
                                            card.cost = cost
                                        }
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
                                    if let health = jsonCard["health"] as? Int {
                                        card.health = health
                                    }
                                    if let flavor = jsonCard["flavor"] as? String {
                                        card.flavor = flavor
                                    }
                                    if let collectible = jsonCard["collectible"] as? Bool {
                                        card.collectible = collectible
                                        
                                        // card is collectible, mark it as needed for download
                                        if lang == imageLanguage {
                                            images.append(card.cardId)
                                        }
                                    }
                                    if let name = jsonCard["name"] as? String {
                                        card.name = name
                                    }
                                    if let text = jsonCard["text"] as? String {
                                        card.text = text
                                    }
                                    
                                    if let mechanics = jsonCard["mechanics"] as? [String] {
                                        for mechanic in mechanics {
                                            let _mechanic = mechanic.lowercaseString
                                            var cardMechanic = CardMechanic.MR_findFirstByAttribute("name", withValue: _mechanic, inContext: localContext)
                                            if cardMechanic == nil {
                                                cardMechanic = CardMechanic.MR_createEntityInContext(localContext)
                                                cardMechanic!.name = _mechanic
                                            }
                                            card.mechanics.insert(cardMechanic!)
                                        }
                                    }
                                }
                            }
                        })
                    }
                } catch {
                    print(error)
                }
            } else {
                // TODO show error
            }
        }
        Settings.instance.databaseVersion = DatabaseVersion
        return images
    }
}