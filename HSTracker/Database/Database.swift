//
//  Database.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class Cards {
    static var cards = [Card]()

    static func heroById(cardId: String) -> Card? {
        if let card = cards.firstWhere({ $0.cardId == cardId && $0.type == "hero" }) {
            return card.copy()
        }
        return nil
    }

    static func isHero(cardId: String?) -> Bool {
        guard !String.isNullOrEmpty(cardId) else { return false }
        
        return heroById(cardId!) != .None
    }

    static func byId(cardId: String?) -> Card? {
        guard !String.isNullOrEmpty(cardId) else { return nil }
        
        if let card = collectible().firstWhere({ $0.cardId == cardId }) {
            return card.copy()
        }
        return nil
    }
    
    static func anyById(cardId: String) -> Card? {
        if let card = cards.firstWhere({ $0.cardId == cardId }) {
            return card.copy()
        }
        return nil
    }

    static func byEnglishName(name: String) -> Card? {
        if let card = collectible().firstWhere({ $0.enName == name }) {
            return card.copy()
        }
        return nil
    }

    private static func collectible() -> [Card] {
        return cards.filter { $0.collectible && $0.type != "hero" && $0.type != "hero power" }
    }

    static func byClass(className: String?, set: String?) -> [Card] {
        var _cards = collectible().filter { $0.playerClass == className }
        if let set = set {
            _cards = _cards.filter { $0.set == set }
        }
        return _cards
    }

    static func search(className: String?, set: String?, term: String) -> [Card] {
        var _cards = collectible().filter { $0.playerClass == className || $0.playerClass == "neutral" }
        if let set = set {
            _cards = _cards.filter { $0.set == set }
        }
        return _cards.filter {
            $0.name.lowercaseString.contains(term.lowercaseString) ||
            $0.enName.lowercaseString.contains(term.lowercaseString) ||
            $0.text.lowercaseString.contains(term.lowercaseString) ||
            ($0.rarity != nil && $0.rarity!.rawValue.contains(term.lowercaseString)) ||
            $0.type.lowercaseString.contains(term.lowercaseString)
        }
    }
}

struct Database {
    static let validCardSet = ["CORE", "EXPERT1", "NAXX", "GVG", "BRM", "TGT", "LOE", "PROMO", "REWARD", "HERO_SKINS"]

    func loadDatabase(splashscreen: Splashscreen?) -> [String]? {
        var imageLanguage = "enUS"
        var langs = [String]()
        if let language = Settings.instance.hearthstoneLanguage where language != "enUS" {
            langs += [language]
            imageLanguage = language
        }
        langs += ["enUS"]

        var images = [String]()

        for lang in langs {
            let jsonFile = NSBundle.mainBundle().resourcePath! + "/Resources/Cards/cardsDB.\(lang).json"
            DDLogVerbose("json file : \(jsonFile)")
            if let jsonData = NSData(contentsOfFile: jsonFile) {
                do {
                    let cards: [[String: AnyObject]] = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as! [[String: AnyObject]]

                    if let splashscreen = splashscreen {
                        dispatch_async(dispatch_get_main_queue()) {
                            splashscreen.display(String(format: NSLocalizedString("Loading %@ cards", comment: ""), lang), total: Double(cards.count))
                        }
                    }

                    for jsonCard in cards {
                        if let splashscreen = splashscreen {
                            dispatch_async(dispatch_get_main_queue()) {
                                splashscreen.increment()
                            }
                        }

                        let set = jsonCard["set"] as! String
                        if !Database.validCardSet.contains(set) {
                            continue
                        }

                        if let cardId = jsonCard["id"] as? String {

                            if lang == "enUS" && langs.count > 1 {
                                if let card = Cards.cards.firstWhere({ $0.cardId == cardId }) {
                                    if let name = jsonCard["name"] as? String {
                                        card.enName = name
                                    }
                                }
                            }
                            else {
                                let card = Card()
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
                                    card.rarity = Rarity(rawValue: cardRarity.lowercaseString)
                                }

                                if let cardType = jsonCard["type"] as? String {
                                    card.type = cardType.lowercaseString
                                }

                                if let cardPlayerClass = jsonCard["playerClass"] as? String {
                                    card.playerClass = cardPlayerClass.lowercaseString
                                }
                                else {
                                    card.playerClass = "neutral"
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
                                    if lang == imageLanguage && card.type != "hero" {
                                        images.append(card.cardId)
                                    }
                                }
                                if let name = jsonCard["name"] as? String {
                                    card.name = name
                                }
                                if let text = jsonCard["text"] as? String {
                                    card.text = text
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
                } catch {
                    print(error)
                }
            } else {
                // TODO show error
            }
        }
        return images
    }
}