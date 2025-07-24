//
//  Database.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Database: NSObject, XMLParserDelegate {
    enum ElementName: String {
        case None, Entity, Tag, deDE, enUS, esES, esMX, frFR, itIT, jaJP, koKR, plPL, ptBR, ruRU, thTH, zhCN, zhTW
    }
    
    static let mechanics: [Int: String] = [
        GameTag.windfury.rawValue: "WINDFURY",
        GameTag.taunt.rawValue: "TAUNT",
        GameTag.stealth.rawValue: "STEALTH",
        GameTag.spellpower.rawValue: "SPELLPOWER",
        GameTag.divine_shield.rawValue: "DIVINE_SHIELD",
        GameTag.charge.rawValue: "CHARGE",
        GameTag.freeze.rawValue: "FREEZE",
        GameTag.enraged.rawValue: "ENRAGE",
        GameTag.deathrattle.rawValue: "DEATHRATTLE",
        GameTag.battlecry.rawValue: "BATTLECRY",
        GameTag.secret.rawValue: "SECRET",
        GameTag.combo.rawValue: "COMBO",
        GameTag.silence.rawValue: "SILENCE",
        GameTag.immunetospellpower.rawValue: "ImmuneToSpellpower",
        GameTag.poisonous.rawValue: "POISONOUS",
        GameTag.lifesteal.rawValue: "LIFESTEAL",
        GameTag.outcast.rawValue: "OUTCAST",
        GameTag.rush.rawValue: "RUSH",
        GameTag.overkill.rawValue: "OVERKILL",
        GameTag.trigger_visual.rawValue: "TRIGGER_VISUAL",
        GameTag.honorable_kill.rawValue: "HONORABLE_KILL",
        GameTag.immune.rawValue: "IMMUNE",
        GameTag.dormant.rawValue: "DORMANT",
        GameTag.discover.rawValue: "DISCOVER",
        GameTag.recruit.rawValue: "RECRUIT",
        GameTag.venomous.rawValue: "VENOMOUS",
        GameTag.choose_one.rawValue: "CHOOSE_ONE",
        GameTag.protoss.rawValue: "PROTOSS",
        GameTag.paladin_aura.rawValue: "PALADIN_AURA",
        GameTag.imp.rawValue: "IMP",
        GameTag.kindred.rawValue: "KINDRED"
    ]
    
    static let currentSeason: Int = {
        let today = Date()
        let dc = Calendar.current.dateComponents(in: TimeZone.current, from: today)
        return (dc.year! - 2014) * 12 - 3 + dc.month!
    }()
    
    static let validCardSets = CardSet.allCases

    static let deckManagerCardTypes = ["all_types", "spell", "minion", "weapon"]
    static var deckManagerRaces = [Race]()

    // list of cards that are incorrectly tagged as BG
    static let battlegroundsExclusions: Set = [ "CORE_LOE_077" ]
    
    static var battlegroundRaces = [Race]()
    
    var cards = [Card]()
    var currentElement = ElementName.None
    var currentLanguage = ""
    var currentCard: Card?
    var currentTag: GameTag?
    var currentText = ""
    var mainLanguage = ""
    var splashScreen: Splashscreen?
    
    func parserDidStartDocument(_ parser: XMLParser) {
        cards.removeAll()
        currentCard = nil
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        switch elementName {
        case "Entity":
            currentElement = .Entity
            currentCard = Card()
            currentCard?.id = attributeDict["CardID"] ?? ""
            currentCard?.dbfId = Int(attributeDict["ID"] ?? "0") ?? 0
        case "Tag":
            currentElement = .Tag
            currentTag = nil
            if let enumID = attributeDict["enumID"], let id = Int(enumID) {
                let intValue = Int(attributeDict["value"] ?? "0") ?? 0
                switch id {
                case GameTag.health.rawValue:
                    currentCard?.health = intValue
                case GameTag.atk.rawValue:
                    currentCard?.attack = intValue
                case GameTag.cost.rawValue:
                    currentCard?.cost = intValue
                case GameTag.rarity.rawValue:
                    currentCard?.rarity = Rarity.allCases[intValue]
                case GameTag.collectible.rawValue:
                    currentCard?.collectible = intValue > 0
                case GameTag.tech_level.rawValue:
                    currentCard?.techLevel = intValue
                case GameTag.is_bacon_pool_minion.rawValue:
                    if !Database.battlegroundsExclusions.contains(currentCard?.id ?? "") {
                        currentCard?.battlegroundsPoolMinion = intValue > 0
                    }
                    currentCard?.isBaconPoolMinion = intValue > 0
                case GameTag.is_bacon_duos_exclusive.rawValue:
                    currentCard?.isBaconDuosExclusive = intValue
                case GameTag.bacon_skin_parent_id.rawValue:
                    currentCard?.battlegroundsSkinParentId = intValue
                case GameTag.hide_stats.rawValue:
                    currentCard?.hideStats = intValue > 0
                case GameTag.cardtype.rawValue:
                    currentCard?.type = CardType(rawValue: intValue) ?? .invalid
                case GameTag.class.rawValue:
                    currentCard?.playerClass = CardClass.allCases[intValue]
                case GameTag.cardrace.rawValue:
                    let race = Race.allCases[intValue]
                    currentCard?.race = race
                    currentCard?.races.append(Race.allCases[intValue])
                case GameTag.multi_class_group.rawValue:
                    currentCard?.multiClassGroup = MultiClassGroup(rawValue: intValue) ?? .invalid
                case GameTag.lettuce_cooldown_config.rawValue:
                    currentCard?.mercenariesAbilityCooldown = intValue
                case GameTag.tourist.rawValue:
                    currentCard?.tourist = intValue
                case GameTag.card_set.rawValue:
                    if let set = CardSetInt(rawValue: intValue) {
                        if let realSet = CardSet(rawValue: "\(set)"), Database.validCardSets.contains(realSet) {
                            currentCard?.set = realSet
                            currentCard?.isStandard = !CardSet.wildSets().contains(realSet) && !CardSet.classicSets().contains(realSet)
                        } else {
                            currentCard = nil
                        }
                    } else {
                        currentCard = nil
                    }
                case GameTag.zilliax_customizable_functionalmodule.rawValue:
                    currentCard?.zilliaxCustomizableFunctionalModule = intValue > 0
                case GameTag.zilliax_customizable_cosmeticmodule.rawValue:
                    currentCard?.zilliaxCustomizableCosmeticModule = intValue > 0
                case GameTag.cardname.rawValue:
                    currentTag = GameTag.cardname
                case GameTag.cardtext.rawValue:
                    currentTag = .cardtext
                case GameTag.flavortext.rawValue:
                    currentTag = .flavortext
                case 2524, 2525, 2526, 2527, 2528, 2529, 2530, 2531, 2532, 2533, 2534, 2536, 2537, 2538, 2539, 2540, 2541, 2542, 2543, 2544, 2522, 2523, 2545, 2546, 2547, 2548, 2549, 2550, 2551, 2552, 2553, 2554, 2555, 2556, 2584, 2585, 2586, 2587, 2588:
                    if let race = RaceUtils.tagRaceMap[id] {
                        currentCard?.races.append(race)
                    }
                case GameTag.is_bacon_pool_spell.rawValue:
                    currentCard?.isBaconPoolSpell = intValue != 0
                case GameTag.windfury.rawValue, GameTag.taunt.rawValue, GameTag.stealth.rawValue, GameTag.spellpower.rawValue, GameTag.divine_shield.rawValue, GameTag.charge.rawValue, GameTag.freeze.rawValue, GameTag.enraged.rawValue, GameTag.deathrattle.rawValue, GameTag.battlecry.rawValue, GameTag.secret.rawValue, GameTag.combo.rawValue, GameTag.silence.rawValue, GameTag.immunetospellpower.rawValue, GameTag.poisonous.rawValue, GameTag.lifesteal.rawValue, GameTag.outcast.rawValue, GameTag.rush.rawValue, GameTag.overkill.rawValue, GameTag.trigger_visual.rawValue, GameTag.honorable_kill.rawValue, GameTag.immune.rawValue, GameTag.dormant.rawValue, GameTag.discover.rawValue, GameTag.venomous.rawValue, GameTag.choose_one.rawValue, GameTag.paladin_aura.rawValue, GameTag.imp.rawValue, GameTag.kindred.rawValue:
                    if let mechanic = Database.mechanics[id] {
                        currentCard?.mechanics.append(mechanic)
                    }
                case GameTag.multiple_classes.rawValue:
                    currentCard?.multipleClasses = intValue
                case GameTag.bacon_triple_upgrade_minion_id.rawValue:
                    currentCard?.baconTripleUpgradeMinionId = intValue
                case GameTag.kabal.rawValue, GameTag.grimy_goons.rawValue, GameTag.jade_lotus.rawValue, GameTag.protoss.rawValue, GameTag.terran.rawValue, GameTag.zerg.rawValue:
                    if intValue > 0 {
                        currentCard?.faction = GameTag(rawValue: id)
                    }
                case GameTag.spell_school.rawValue:
                    currentCard?.spellSchool = SpellSchool(rawValue: intValue) ?? .none
                case GameTag.bacon_hero_can_be_drafted.rawValue:
                    currentCard?.baconHeroCanBeDrafted = intValue != 0
                default:
                    break
                }
            }
        case "ReferencedTag":
            if let enumID = attributeDict["enumID"], let id = Int(enumID) {
//                let intValue = Int(attributeDict["value"] ?? "0") ?? 0
                if let mechanic = Database.mechanics[id] {
                    currentCard?.mechanics.append(mechanic)
                }
            }
        case "deDE", "enUS", "esES", "esMX", "frFR", "itIT", "jaJP", "koKR", "plPL", "ptBR", "ruRU", "thTH", "zhCN", "zhTW":
            assert(currentElement == .Tag)
            if elementName == mainLanguage {
                currentLanguage = elementName
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "Entity":
            if let card = currentCard {
                if let set = card.set {
                    card.isStandard = !CardSet.wildSets().contains(set) && !CardSet.classicSets().contains(set)
                }
                cards.append(card)
                if card.collectible && card.race != .invalid && card.race != .all && !Database.deckManagerRaces.contains(card.race) && CardSet.deckManagerValidCardSets().contains(card.set ?? .invalid) {
                    Database.deckManagerRaces.append(card.race)
                }
                splashScreen?.increment()
                let index = Cards.cards.endIndex //Cards.indexOf(id: card.id)
//                if index < 0 {
//                    index = -index - 1
//                }
                Cards.cards.insert(card, at: index)
                Cards.cardsById[card.id] = card
                if card.battlegroundsPoolMinion && !Cards.battlegroundsMinions.contains(card) {
                    Cards.battlegroundsMinions.append(card)
                }
            }
            currentCard = nil
            currentTag = nil
        case "Tag":
            currentTag = nil
        case "deDE", "enUS", "esES", "esMX", "frFR", "itIT", "jaJP", "koKR", "plPL", "ptBR", "ruRU", "thTH", "zhCN", "zhTW":
            if !currentLanguage.isEmpty {
                if currentTag == .cardname {
                    currentCard?.name = currentText
                    if elementName == "enUS" {
                        currentCard?.enName = currentText
                    }
                } else if currentTag == .cardtext {
                    currentCard?.text = currentText
                    if elementName == "enUS" {
                        currentCard?.enText = currentText
                    }
                } else if currentTag == .flavortext {
                    currentCard?.flavor = currentText
                }
                currentLanguage = ""
                currentText = ""
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !currentLanguage.isEmpty {
            currentText += string
        }
    }

    func loadDatabase(splashscreen: Splashscreen?, withLanguages langs: [Language.Hearthstone]) {
        autoreleasepool {
            guard let file = Bundle(for: type(of: self)).url(forResource: "Resources/Cards/CardDefs", withExtension: "xml") else {
                logger.error("Can't find CardDefs.xml")
                return
            }
            guard let data = try? Data(contentsOf: file) else {
                logger.error("\(file) failed to get contents")
                return
            }
            let parser = XMLParser(data: data)
            parser.delegate = self
            mainLanguage = langs[0].rawValue
            let msg = String(format: String.localizedString("Loading %@ cards",
                                                       comment: ""), mainLanguage)
            splashscreen?.display(msg, indeterminate: true)

            self.splashScreen = splashscreen
            guard parser.parse() else {
                logger.error("Failed to parse contents. Error: \(parser.parserError?.localizedDescription ?? "unknown")")
                return
            }
            for card in Cards.battlegroundsMinions.array() {
                if card.race != .invalid && card.race != .all && !Database.battlegroundRaces.contains(card.race) {
                    Database.battlegroundRaces.append(card.race)
                }
                if card.races.count > 0 && card.races[0] != .all {
                    for race in card.races where !Database.battlegroundRaces.contains(race) {
                        Database.battlegroundRaces.append(race)
                    }
                }
            }
        }
    }
}
