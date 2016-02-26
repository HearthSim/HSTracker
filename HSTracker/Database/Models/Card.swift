//
//  Card.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Card : CustomStringConvertible {

    var cardId: String = ""
    var collectible: Bool = false
    var cost: Int = 0
    var faction: String = ""
    var flavor: String = ""
    var health: Int = 0
    var name: String = ""
    var enName: String = ""
    var playerClass: String = ""
    var rarity: String = ""
    var set: String = ""
    var text: String = ""
    var type: String = ""
    //var mechanics: Set<CardMechanic>
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
        var color:NSColor
        if  highlightDraw && Settings.instance.highlightLastDrawn {
            color = NSColor(red:1, green:0.647, blue:0, alpha:1)
        }
        else if highlightInHand && Settings.instance.highlightCardsInHand {
            color = NSColor(red:0.678, green:1, blue:0.184, alpha:1)
        }
        else if count <= 0 || jousted {
            color = NSColor(red:0.501, green:0.501, blue:0.501, alpha:1)
        }
        else if wasDiscarded && Settings.instance.highlightDiscarded {
            color = NSColor(red:0.803, green:0.36, blue:0.36, alpha:1)
        }
        else {
            color = NSColor.whiteColor()
        }
        return color
    }
    
    func copy() -> AnyObject {
        let copy = Card()
        copy.cardId = self.cardId
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
        //copy.mechanics = self.mechanics
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
        return "<\(NSStringFromClass(self.dynamicType)): "
            + "self.cardId=\(self.cardId)"
            + ", self.collectible=\(self.collectible)"
            + ", self.cost=\(self.cost)"
            + ", self.faction=\(self.faction)"
            //+ ", self.flavor=\(self.flavor)"
            //+ ", self.health=\(self.health)"
            + ", self.name=\(self.name)"
            + ", self.enName=\(self.enName)"
            + ", self.playerClass=\(self.playerClass)"
            + ", self.rarity=\(self.rarity)"
            + ", self.set=\(self.set)"
            //+ ", self.text=\(self.text)"
            + ", self.type=\(self.type)"
            //+ ", self.mechanics=\(self.mechanics)"
            //+ ", self.isStandard=\(self.isStandard)"
            + ", self.count=\(self.count)"
            + ", self.hasChanged=\(self.hasChanged)"
            + ", self.jousted=\(self.jousted)"
            + ", self.isStolen=\(self.isStolen)"
            + ", self.isCreated=\(self.isCreated)"
            + ", self.wasDiscarded=\(self.wasDiscarded)"
            + ", self.highlightDraw=\(self.highlightDraw)"
            + ", self.highlightInHand=\(self.highlightInHand)"
            + ", self.highlightFrame=\(self.highlightFrame)>"
    }

}
