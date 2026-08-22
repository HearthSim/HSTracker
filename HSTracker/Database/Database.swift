//
//  Database.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Database {
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
        GameTag.kindred.rawValue: "KINDRED",
        GameTag.elite.rawValue: "ELITE",
        // Battlegrounds keyword filters (see BattlegroundsKeyword). HDT reads these
        // straight off the entity with card.GetTag; HSTracker only keeps the curated
        // mechanics list below, so each tag a keyword filter needs has to be named here.
        GameTag.reborn.rawValue: "REBORN",
        GameTag.modular.rawValue: "MODULAR",
        GameTag.avenge.rawValue: "AVENGE",
        GameTag.bacon_rally.rawValue: "BACON_RALLY",
        GameTag.start_of_combat.rawValue: "START_OF_COMBAT",
        GameTag.end_of_turn_trigger.rawValue: "END_OF_TURN_TRIGGER",
        GameTag.bacon_activate_tooltip.rawValue: "BACON_ACTIVATE_TOOLTIP"
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

    /// The card currently being filled in. The CARD_SET case drops an entity by
    /// setting this to nil when the set is one HSTracker does not know about;
    /// every later assignment then no-ops through the optional chain.
    var currentCard: Card?
    var mainLanguage = ""
    private var displayLanguage: Int?
    private var englishLanguage: Int?

    func loadDatabase(splashscreen: Splashscreen?, withLanguages langs: [Language.Hearthstone]) {
        autoreleasepool {
            guard let file = Bundle(for: type(of: self)).url(forResource: "CardDefs",
                                                            withExtension: "bin") else {
                logger.error("Can't find CardDefs.bin")
                return
            }
            guard let reader = CardDefsReader(url: file) else {
                logger.error("\(file) is not a readable card database")
                return
            }

            mainLanguage = langs[0].rawValue
            englishLanguage = reader.languageIndex(of: Language.Hearthstone.enUS.rawValue)
            displayLanguage = reader.languageIndex(of: mainLanguage)
            if displayLanguage == nil {
                logger.error("\(mainLanguage) is missing from the card database, using enUS")
                displayLanguage = englishLanguage
            }

            let msg = String(format: String.localizedString("Loading %@ cards",
                                                       comment: ""), mainLanguage)
            splashscreen?.display(msg, indeterminate: true)

            let started = Date()
            reader.forEachEntity { entity in
                load(entity)
            }
            logger.info("Loaded \(Cards.cards.count) \(mainLanguage) cards in "
                        + String(format: "%.3fs", -started.timeIntervalSinceNow))

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

    private func load(_ entity: CardDefsEntity) {
        let card = Card()
        card.id = entity.cardId
        card.dbfId = entity.dbfId
        currentCard = card

        for index in 0..<entity.tagCount {
            let tag = entity.tag(at: index)
            if tag.id < 0 {
                // A negated id marks a <ReferencedTag>, which only ever
                // contributes a mechanic.
                if let mechanic = Database.mechanics[-tag.id] {
                    currentCard?.mechanics.append(mechanic)
                }
            } else {
                apply(tag: tag.id, value: tag.value)
            }
        }
        for index in 0..<entity.localizedCount {
            apply(localized: entity, at: index)
        }
        finish()
    }

    private func apply(tag id: Int, value intValue: Int) {

        switch id {
        case GameTag.health.rawValue:
            currentCard?.health = intValue
        case GameTag.atk.rawValue:
            currentCard?.attack = intValue
        case GameTag.cost.rawValue:
            currentCard?.cost = intValue
        case GameTag.overload.rawValue:
            currentCard?.overload = intValue
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
                    currentCard?.isStandard = !CardSet.wildSets.contains(realSet) && !CardSet.classicSets.contains(realSet)
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
        case 2524, 2525, 2526, 2527, 2528, 2529, 2530, 2531, 2532, 2533, 2534, 2536, 2537, 2538, 2539, 2540, 2541, 2542, 2543, 2544, 2522, 2523, 2545, 2546, 2547, 2548, 2549, 2550, 2551, 2552, 2553, 2554, 2555, 2556, 2584, 2585, 2586, 2587, 2588:
            if let race = RaceUtils.tagRaceMap[id] {
                currentCard?.races.append(race)
            }
        case GameTag.is_bacon_pool_spell.rawValue:
            currentCard?.isBaconPoolSpell = intValue != 0
        case GameTag.windfury.rawValue, GameTag.taunt.rawValue, GameTag.stealth.rawValue, GameTag.spellpower.rawValue, GameTag.divine_shield.rawValue, GameTag.charge.rawValue, GameTag.freeze.rawValue, GameTag.enraged.rawValue, GameTag.deathrattle.rawValue, GameTag.battlecry.rawValue, GameTag.secret.rawValue, GameTag.combo.rawValue, GameTag.silence.rawValue, GameTag.immunetospellpower.rawValue, GameTag.poisonous.rawValue, GameTag.lifesteal.rawValue, GameTag.outcast.rawValue, GameTag.rush.rawValue, GameTag.overkill.rawValue, GameTag.trigger_visual.rawValue, GameTag.honorable_kill.rawValue, GameTag.immune.rawValue, GameTag.dormant.rawValue, GameTag.discover.rawValue, GameTag.venomous.rawValue, GameTag.choose_one.rawValue, GameTag.paladin_aura.rawValue, GameTag.imp.rawValue, GameTag.kindred.rawValue, GameTag.elite.rawValue, GameTag.reborn.rawValue, GameTag.modular.rawValue, GameTag.avenge.rawValue, GameTag.bacon_rally.rawValue, GameTag.start_of_combat.rawValue, GameTag.end_of_turn_trigger.rawValue, GameTag.bacon_activate_tooltip.rawValue:
            if let mechanic = Database.mechanics[id] {
                currentCard?.mechanics.append(mechanic)
            }
        case GameTag.multiple_classes.rawValue:
            currentCard?.multipleClasses = intValue
        case GameTag.bacon_triple_upgrade_minion_id.rawValue:
            currentCard?.baconTripleUpgradeMinionId = intValue
        case GameTag.hide_cost.rawValue:
            currentCard?.hideCostTag = intValue == 1
        case GameTag.bacon_buddy.rawValue:
            currentCard?.isBaconBuddy = intValue == 1
        case GameTag.bacon_tripled_base_minion_id.rawValue:
            currentCard?.baconTripledBaseMinionId = intValue
        case GameTag.kabal.rawValue, GameTag.grimy_goons.rawValue, GameTag.jade_lotus.rawValue, GameTag.protoss.rawValue, GameTag.terran.rawValue, GameTag.zerg.rawValue:
            if intValue > 0 {
                currentCard?.faction = GameTag(rawValue: id)
            }
        case GameTag.spell_school.rawValue:
            currentCard?.spellSchool = SpellSchool(rawValue: intValue) ?? .none
        default:
            break
        }
    }

    /// The three localized tags HSTracker keeps. enUS is captured alongside the
    /// display language, not only when it *is* the display language: enName and
    /// enText are what English-invariant matching reads (BattlegroundsDb's
    /// race-in-text detection, and BattlegroundsKeyword's text fallback).
    ///
    /// A language the XML has no element for reads back as nil and leaves the
    /// Card default alone, which is what the old parser did by never firing a
    /// didEndElement for it.
    private func apply(localized entity: CardDefsEntity, at index: Int) {
        switch entity.localizedTagId(at: index) {
        case GameTag.cardname.rawValue:
            if let value = entity.localizedString(at: index, language: displayLanguage) {
                currentCard?.name = value
            }
            if let value = entity.localizedString(at: index, language: englishLanguage) {
                currentCard?.enName = value
            }
        case GameTag.cardtext.rawValue:
            if let value = entity.localizedString(at: index, language: displayLanguage) {
                currentCard?.text = value
            }
            if let value = entity.localizedString(at: index, language: englishLanguage) {
                currentCard?.enText = value
            }
        case GameTag.flavortext.rawValue:
            if let value = entity.localizedString(at: index, language: displayLanguage) {
                currentCard?.flavor = value
            }
        default:
            break
        }
    }

    private func finish() {
        defer {
            currentCard = nil
        }
        guard let card = currentCard else {
            return
        }
        if let set = card.set {
            card.isStandard = !CardSet.wildSets.contains(set) && !CardSet.classicSets.contains(set)
        }
        if card.collectible && card.race != .invalid && card.race != .all && !Database.deckManagerRaces.contains(card.race) && CardSet.deckManagerCardSetLookup.contains(card.set ?? .invalid) {
            Database.deckManagerRaces.append(card.race)
        }
        Cards.cards.append(card)
        Cards.cardsById[card.id] = card
        if card.battlegroundsPoolMinion && !Cards.battlegroundsMinions.contains(card) {
            Cards.battlegroundsMinions.append(card)
        }
    }
}
