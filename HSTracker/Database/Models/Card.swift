//
//  Card.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
//import HearthAssets
import RegexUtil

final class Card {
    // MARK: - Card data
    var id = ""
    var dbfId = 0
    var collectible = false
    var cost = 0
    var faction: Faction = .invalid
    var flavor = ""
    var health = 0
    var attack = 0
    var overload = 0
    var durability = 0
    var name = "unknown"
    var enName = ""
    var playerClass: CardClass = .neutral
    var rarity: Rarity = .free
    var set: CardSet?
    var text = ""
    var enText = ""
    var race: Race = .invalid
    var bgRace: Race = .invalid
    var type: CardType = .invalid
    var mechanics: [CardMechanic] = []
    var isStandard = false
    var artist = ""
    var multiClassGroup: MultiClassGroup = .invalid
    var techLevel = 0
    var jsonRepresentation: [String: Any] = [:]
    var hideStats = false
    var mercenariesAbilityCooldown = 0
    var battlegroundsPoolMinion = false
    var deckListIndex = 0
    
    static let multiClassGroups: [MultiClassGroup: [CardClass]] = [
        .grimy_goons: [ .hunter, .paladin, .warrior ],
        .jade_lotus: [ .druid, .rogue, .shaman ],
        .kabal: [ .mage, .priest, .warlock ],
        .druid_hunter: [ .druid, .hunter ],
        .druid_shaman: [ .druid, .shaman ],
        .hunter_demonhunter: [ .hunter, .demonhunter ],
        .mage_rogue: [ .mage, .rogue ],
        .mage_shaman: [ .mage, .shaman ],
        .paladin_priest: [ .paladin, .priest ],
        .paladin_warrior: [ .paladin, .warrior ],
        .priest_warlock: [ .priest, .warlock ],
        .rogue_warrior: [ .rogue, .warrior ],
        .warlock_demonhunter: [ .warlock, .demonhunter ]
    ]

    // arena helper
    var isBadAsMultiple = false

    // MARK: - deck / games
    var count = 0
    var hasChanged = false

    var jousted = false
    var isStolen = false
    var isCreated = false
    var wasDiscarded = false
    var highlightDraw = false
    var highlightInHand = false
    var highlightFrame = false

    var englishName: String {
        if let language = Settings.hearthstoneLanguage, language == .enUS {
            return self.name
        }
        return self.enName
    }
    
    func isClass(cardClass: CardClass) -> Bool {
        if playerClass == cardClass {
            return true
        }
        
        if multiClassGroup == .invalid {
            return false
        }
        
        return Card.multiClassGroups[multiClassGroup]?.first(where: { cc in
            cc == cardClass
        }) != nil
    }

    func formattedText() -> String {
        let pluralRegex: RegexPattern = "\\$(\\d+) \\|4\\((\\w+),(\\w+)\\)"
        return text.replace(pluralRegex, using: { string, matches in
            guard matches.count == 4 else { return string }

            let single = matches[1].value
            let plural = matches[2].value
            let count = Int(matches[0].value) ?? 0

            let replace = "\(count) \(count <= 1 ? single : plural)"
            return string.replace(pluralRegex, with: replace)
        }).replace("\\$", with: "")
            .replace("<b>", with: "")
            .replace("</b>", with: "")
            .replace("<i>", with: "")
            .replace("</i>", with: "")
            .replace("#", with: "")
            .replace("\\n", with: "\n")
            .replace("\\[x\\]", with: "")
    }

    func textColor() -> NSColor {
        var color = NSColor.white
        if highlightDraw && Settings.highlightLastDrawn {
            color = NSColor(red: 1, green: 0.647, blue: 0, alpha: 1)
        } else if highlightInHand && Settings.highlightCardsInHand {
            color = Settings.playerInHandColor
        } else if count <= 0 || jousted {
            color = NSColor(red: 0.501, green: 0.501, blue: 0.501, alpha: 1)
        } else if wasDiscarded && Settings.highlightDiscarded {
            color = NSColor(red: 0.803, green: 0.36, blue: 0.36, alpha: 1)
        }
        return color
    }
    
    init() {
    }
    
    init(fromRealCard: RealmCard) {
        self.id = fromRealCard.id
        self.count = fromRealCard.count
    }
    
    static func < (left: Card, right: Card) -> Bool {
        if left.cost == right.cost {
            return left.name < right.name
        }
        return left.cost < right.cost
    }
}

extension Card: NSCopying {

    func copy() -> Card {
        // swiftlint:disable force_cast
        return copy(with: nil) as! Card
        // swiftlint:enable force_cast
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Card()
        copy.id = self.id
        copy.dbfId = self.dbfId
        copy.collectible = self.collectible
        copy.cost = self.cost
        copy.faction = self.faction
        copy.flavor = self.flavor
        copy.health = self.health
        copy.attack = self.attack
        copy.durability = self.durability
        copy.name = self.name
        copy.enName = self.enName
        copy.playerClass = self.playerClass
        copy.rarity = self.rarity
        copy.set = self.set
        copy.text = self.text
        copy.race = self.race
        copy.type = self.type
        copy.overload = self.overload
        copy.mechanics = self.mechanics
        copy.isStandard = self.isStandard
        copy.artist = self.artist
        copy.count = self.count
        copy.hasChanged = self.hasChanged
        copy.jousted = self.jousted
        copy.isStolen = self.isStolen
        copy.isCreated = self.isCreated
        copy.wasDiscarded = self.wasDiscarded
        copy.highlightDraw = self.highlightDraw
        copy.highlightInHand = self.highlightInHand
        copy.highlightFrame = self.highlightFrame
        copy.jsonRepresentation = self.jsonRepresentation
        copy.multiClassGroup = self.multiClassGroup
        copy.techLevel = self.techLevel
        copy.hideStats = self.hideStats
        copy.mercenariesAbilityCooldown = self.mercenariesAbilityCooldown
        copy.battlegroundsPoolMinion = self.battlegroundsPoolMinion
        copy.deckListIndex = self.deckListIndex

        return copy
    }
}

extension Card: CustomStringConvertible {
    var description: String {
        return "[\(name)(\(id)):\(count)]"
    }
}

extension Card: Hashable {
    
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.id == rhs.id
    }
}

/*extension HearthAssets {
    func generate(card: Card,
                  completed: @escaping ((NSImage?, HearthAssets.AssetError?) -> Void)) {
        generate(card: card.jsonRepresentation, completed: completed)
    }

    func tile(card: Card,
              completed: @escaping ((NSImage?, HearthAssets.AssetError?) -> Void)) {
        tile(card: card.jsonRepresentation, completed: completed)
    }
}*/
