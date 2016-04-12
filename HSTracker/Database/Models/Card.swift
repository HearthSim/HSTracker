//
//  Card.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class Card : Hashable, CustomStringConvertible {

    var id: String = ""
    var collectible: Bool = false
    var cost: Int = 0
    var faction: String = ""
    var flavor: String = ""
    var health: Int = 0
    var name: String = "unknown"
    var enName: String = ""
    var playerClass: String = ""
    var rarity: Rarity = .Free
    var set: String = ""
    var text: String = ""
    var type: String = "unknown"
    // var mechanics: Set<CardMechanic>
    var isStandard: Bool = false

    var count: Int = 0
    var hasChanged: Bool = false

    var jousted: Bool = false
    var isStolen: Bool = false
    var isCreated: Bool = false
    var wasDiscarded: Bool = false

    var highlightDraw: Bool = false
    var highlightInHand: Bool = false
    var highlightFrame: Bool = false

    var englishName: String {
        if let language = Settings.instance.hearthstoneLanguage where language == "enUS" {
            return self.name
        }
        return self.enName
    }

    func textColor() -> NSColor {
        var color: NSColor
        if highlightDraw && Settings.instance.highlightLastDrawn {
            color = NSColor(red: 1, green: 0.647, blue: 0, alpha: 1)
        }
        else if highlightInHand && Settings.instance.highlightCardsInHand {
            color = NSColor(red: 0.678, green: 1, blue: 0.184, alpha: 1)
        }
        else if count <= 0 || jousted {
            color = NSColor(red: 0.501, green: 0.501, blue: 0.501, alpha: 1)
        }
        else if wasDiscarded && Settings.instance.highlightDiscarded {
            color = NSColor(red: 0.803, green: 0.36, blue: 0.36, alpha: 1)
        }
        else {
            color = NSColor.whiteColor()
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
        copy.name = self.name
        copy.enName = self.enName
        copy.playerClass = self.playerClass
        copy.rarity = self.rarity
        copy.set = self.set
        copy.text = self.text
        copy.type = self.type
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

    var description : String {
        return "[\(name)(\(id)):\(count)]"
    }

    var hashValue: Int {
        return id.hashValue
    }
}
func == (lhs: Card, rhs: Card) -> Bool {
    return lhs.id == rhs.id
}
