//
//  Card.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class Card: Hashable, CustomStringConvertible {
    // MARK: - Card data
    var id = ""
    var collectible = false
    var cost = 0
    var faction: Faction = .invalid
    var flavor = ""
    var health = 0
    var attack = 0
    var name = "unknown"
    var enName = ""
    var playerClass: CardClass = .neutral
    var rarity: Rarity = .free
    var set: CardSet?
    var text = ""
    var race: Race = .invalid
    var type: CardType = .invalid
    // var mechanics: Set<CardMechanic>
    var isStandard = false

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
        if let language = Settings.instance.hearthstoneLanguage, language == "enUS" {
            return self.name
        }
        return self.enName
    }

    func textColor() -> NSColor {
        var color: NSColor
        if highlightDraw && Settings.instance.highlightLastDrawn {
            color = NSColor(red: 1, green: 0.647, blue: 0, alpha: 1)
        } else if highlightInHand && Settings.instance.highlightCardsInHand {
            color = Settings.instance.playerInHandColor
        } else if count <= 0 || jousted {
            color = NSColor(red: 0.501, green: 0.501, blue: 0.501, alpha: 1)
        } else if wasDiscarded && Settings.instance.highlightDiscarded {
            color = NSColor(red: 0.803, green: 0.36, blue: 0.36, alpha: 1)
        } else {
            color = NSColor.white
        }
        return color
    }

    func copy() -> Card {
        let copy = Card()
        copy.id = self.id
        copy.collectible = self.collectible
        copy.cost = self.cost
        copy.faction = self.faction
        copy.flavor = self.flavor
        copy.health = self.health
        copy.attack = self.attack
        copy.name = self.name
        copy.enName = self.enName
        copy.playerClass = self.playerClass
        copy.rarity = self.rarity
        copy.set = self.set
        copy.text = self.text
        copy.type = self.type
        copy.race = self.race
        // copy.mechanics = self.mechanics
        copy.isStandard = self.isStandard
        copy.count = self.count
        copy.hasChanged = self.hasChanged
        copy.jousted = self.jousted
        copy.isStolen = self.isStolen
        copy.isCreated = self.isCreated
        copy.wasDiscarded = self.wasDiscarded
        copy.highlightDraw = self.highlightDraw
        copy.highlightInHand = self.highlightInHand
        copy.highlightFrame = self.highlightFrame
        return copy
    }

    var description: String {
        return "[\(name)(\(id)):\(count)]"
    }

    var hashValue: Int {
        return id.hashValue
    }
}
func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.id == rhs.id
}
